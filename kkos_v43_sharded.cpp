#include <iostream>
#include <vector>
#include <array>
#include <atomic>
#include <thread>
#include <mutex>
#include <shared_mutex>
#include <unordered_map>
#include <fstream>
#include <chrono>
#include <cstring>
#include <csignal>
#include <queue>
#include <condition_variable>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#pragma comment(lib, "ws2_32.lib")
typedef SOCKET socket_t;
#define CLOSE_SOCKET closesocket
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
typedef int socket_t;
#define CLOSE_SOCKET close
#endif

// ============================================================================
// SECTION 0: NATIVE XXHASH64 - NO EXTERNAL DEPS
// ============================================================================
namespace xxh {
constexpr uint64_t PRIME64_1 = 0x9E3779B185EBCA87ULL;
constexpr uint64_t PRIME64_2 = 0xC2B2AE3D27D4EB4FULL;
constexpr uint64_t PRIME64_3 = 0x165667B19E3779F9ULL;
constexpr uint64_t PRIME64_4 = 0x85EBCA77C2B2AE63ULL;
constexpr uint64_t PRIME64_5 = 0x27D4EB2F165667C5ULL;

static inline uint64_t rotl64(uint64_t x, int r) { return (x << r) | (x >> (64 - r)); }

uint64_t xxhash64(const void* input, size_t len, uint64_t seed = 0) {
    const uint8_t* p = (const uint8_t*)input;
    const uint8_t* const bEnd = p + len;
    uint64_t h64;

    if (len >= 32) {
        const uint8_t* const limit = bEnd - 32;
        uint64_t v1 = seed + PRIME64_1 + PRIME64_2;
        uint64_t v2 = seed + PRIME64_2;
        uint64_t v3 = seed + 0;
        uint64_t v4 = seed - PRIME64_1;
        do {
            v1 = rotl64(v1 + (*(uint64_t*)p) * PRIME64_2, 31) * PRIME64_1; p += 8;
            v2 = rotl64(v2 + (*(uint64_t*)p) * PRIME64_2, 31) * PRIME64_1; p += 8;
            v3 = rotl64(v3 + (*(uint64_t*)p) * PRIME64_2, 31) * PRIME64_1; p += 8;
            v4 = rotl64(v4 + (*(uint64_t*)p) * PRIME64_2, 31) * PRIME64_1; p += 8;
        } while (p <= limit);
        h64 = rotl64(v1, 1) + rotl64(v2, 7) + rotl64(v3, 12) + rotl64(v4, 18);
        v1 = rotl64(v1 * PRIME64_2, 31) * PRIME64_1; h64 ^= v1; h64 = h64 * PRIME64_1 + PRIME64_4;
        v2 = rotl64(v2 * PRIME64_2, 31) * PRIME64_1; h64 ^= v2; h64 = h64 * PRIME64_1 + PRIME64_4;
        v3 = rotl64(v3 * PRIME64_2, 31) * PRIME64_1; h64 ^= v3; h64 = h64 * PRIME64_1 + PRIME64_4;
        v4 = rotl64(v4 * PRIME64_2, 31) * PRIME64_1; h64 ^= v4; h64 = h64 * PRIME64_1 + PRIME64_4;
    } else {
        h64 = seed + PRIME64_5;
    }
    h64 += len;
    while (p + 8 <= bEnd) { uint64_t k1 = *(uint64_t*)p; k1 *= PRIME64_2; k1 = rotl64(k1, 31); k1 *= PRIME64_1; h64 ^= k1; h64 = rotl64(h64, 27) * PRIME64_1 + PRIME64_4; p += 8; }
    if (p + 4 <= bEnd) { h64 ^= *(uint32_t*)p * PRIME64_1; h64 = rotl64(h64, 23) * PRIME64_2 + PRIME64_3; p += 4; }
    while (p < bEnd) { h64 ^= *p * PRIME64_5; h64 = rotl64(h64, 11) * PRIME64_1; p++; }
    h64 ^= h64 >> 33; h64 *= PRIME64_2; h64 ^= h64 >> 29; h64 *= PRIME64_3; h64 ^= h64 >> 32;
    return h64;
}
}

// ============================================================================
// SECTION 1: RFC6455 PACKED STRUCTS - EXACT BYTE ALIGNMENT
// ============================================================================
#pragma pack(push, 1)
struct KKOS_PacketHeader {
    uint32_t magic = 0x4B4B4F53; // 'KKOS'
    uint16_t version = 43;
    uint16_t packet_type;
    uint64_t timestamp_ns;
    uint64_t frame_seq;
    uint32_t payload_len;
    uint32_t crc32;
};

struct CoherenceSnapshot {
    int32_t coherence_score;
    uint8_t state_flags; // bit0=inoculated, bit1=collapsed, bit2=sustaining, bit3=chofe
    uint8_t kid_mode;
    float synchronization;
    float stability;
    float sustainability;
    float runtime_integrity;
    float stress_load;
    float entropy;
    float error_propagation;
    uint64_t lane_a_hash;
    uint64_t lane_b_hash;
    uint32_t active_shard_count;
    uint32_t sustain_boost_millipct;
};

struct RollbackEvent {
    uint64_t failed_frame_seq;
    uint64_t rollback_to_seq;
    uint64_t lane_a_hash_at_fail;
    uint64_t lane_b_hash_at_fail;
};
#pragma pack(pop)

static_assert(sizeof(KKOS_PacketHeader) == 32, "Header must be 32B");
static_assert(sizeof(CoherenceSnapshot) == 58, "CoherenceSnapshot size must match binary wire payload");
static_assert(sizeof(RollbackEvent) == 32, "RollbackEvent size must match binary wire payload");

// ============================================================================
// SECTION 2: CRC32 ISO-HDLC
// ============================================================================
uint32_t crc32(const void* data, size_t len) {
    static uint32_t table[256];
    static bool init = false;
    if (!init) {
        for (uint32_t i = 0; i < 256; i++) {
            uint32_t c = i;
            for (int j = 0; j < 8; j++) c = (c & 1)? (0xEDB88320 ^ (c >> 1)) : (c >> 1);
            table[i] = c;
        }
        init = true;
    }
    uint32_t crc = 0xFFFFFFFF;
    const uint8_t* p = (const uint8_t*)data;
    for (size_t i = 0; i < len; i++) crc = table[(crc ^ p[i]) & 0xFF] ^ (crc >> 8);
    return crc ^ 0xFFFFFFFF;
}

static std::string base64_encode(const std::vector<uint8_t>& input) {
    static const char* alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    std::string result;
    result.reserve(((input.size() + 2) / 3) * 4);
    for (size_t i = 0; i < input.size(); i += 3) {
        uint32_t value = 0;
        value |= input[i] << 16;
        if (i + 1 < input.size()) value |= input[i + 1] << 8;
        if (i + 2 < input.size()) value |= input[i + 2];

        result.push_back(alphabet[(value >> 18) & 0x3F]);
        result.push_back(alphabet[(value >> 12) & 0x3F]);
        if (i + 1 < input.size()) result.push_back(alphabet[(value >> 6) & 0x3F]);
        else result.push_back('=');
        if (i + 2 < input.size()) result.push_back(alphabet[value & 0x3F]);
        else result.push_back('=');
    }
    return result;
}

static uint32_t sha1_rotate(uint32_t value, unsigned int bits) {
    return (value << bits) | (value >> (32 - bits));
}

static std::vector<uint8_t> sha1(const std::vector<uint8_t>& data) {
    std::vector<uint8_t> message(data.begin(), data.end());
    const uint64_t bit_len = static_cast<uint64_t>(data.size()) * 8ULL;
    message.push_back(0x80);
    while ((message.size() % 64) != 56) message.push_back(0x00);
    for (int i = 7; i >= 0; --i) message.push_back(static_cast<uint8_t>((bit_len >> (8 * i)) & 0xFF));

    uint32_t h0 = 0x67452301;
    uint32_t h1 = 0xEFCDAB89;
    uint32_t h2 = 0x98BADCFE;
    uint32_t h3 = 0x10325476;
    uint32_t h4 = 0xC3D2E1F0;

    for (size_t chunk = 0; chunk < message.size(); chunk += 64) {
        uint32_t w[80] = {0};
        for (int i = 0; i < 16; ++i) {
            size_t offset = chunk + i * 4;
            w[i] = (static_cast<uint32_t>(message[offset]) << 24) |
                   (static_cast<uint32_t>(message[offset + 1]) << 16) |
                   (static_cast<uint32_t>(message[offset + 2]) << 8) |
                   static_cast<uint32_t>(message[offset + 3]);
        }
        for (int i = 16; i < 80; ++i) {
            w[i] = sha1_rotate(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
        }

        uint32_t a = h0;
        uint32_t b = h1;
        uint32_t c = h2;
        uint32_t d = h3;
        uint32_t e = h4;

        for (int i = 0; i < 80; ++i) {
            uint32_t f, k;
            if (i < 20) {
                f = (b & c) | ((~b) & d);
                k = 0x5A827999;
            } else if (i < 40) {
                f = b ^ c ^ d;
                k = 0x6ED9EBA1;
            } else if (i < 60) {
                f = (b & c) | (b & d) | (c & d);
                k = 0x8F1BBCDC;
            } else {
                f = b ^ c ^ d;
                k = 0xCA62C1D6;
            }
            uint32_t temp = sha1_rotate(a, 5) + f + e + k + w[i];
            e = d;
            d = c;
            c = sha1_rotate(b, 30);
            b = a;
            a = temp;
        }

        h0 += a;
        h1 += b;
        h2 += c;
        h3 += d;
        h4 += e;
    }

    std::vector<uint8_t> digest(20);
    uint32_t hashParts[5] = {h0, h1, h2, h3, h4};
    for (int i = 0; i < 5; ++i) {
        digest[i * 4 + 0] = static_cast<uint8_t>((hashParts[i] >> 24) & 0xFF);
        digest[i * 4 + 1] = static_cast<uint8_t>((hashParts[i] >> 16) & 0xFF);
        digest[i * 4 + 2] = static_cast<uint8_t>((hashParts[i] >> 8) & 0xFF);
        digest[i * 4 + 3] = static_cast<uint8_t>(hashParts[i] & 0xFF);
    }
    return digest;
}

static std::string compute_websocket_accept(const std::string& key) {
    const char guid[] = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
    std::vector<uint8_t> payload(key.begin(), key.end());
    payload.insert(payload.end(), guid, guid + sizeof(guid) - 1);
    return base64_encode(sha1(payload));
}

// ============================================================================
// SECTION 3: SHARDED CORE STATE + LANE C
// ============================================================================
struct ShardedCoreState {
    std::array<float, 8> shard_metrics; // 8 shards * 4B = 32B
    uint64_t frame_seq;
    uint8_t state_flags;
};

class LaneC_RollbackController {
    std::unordered_map<uint64_t, ShardedCoreState> snapshot_cache;
    mutable std::shared_mutex cache_mtx;
    std::atomic<uint64_t> last_known_good_seq{0};
public:
    std::atomic<ShardedCoreState*> lane_a_live_ptr{nullptr};
    std::vector<socket_t> ws_clients;
    std::mutex ws_mtx;

    void broadcast(uint16_t type, const void* payload, uint32_t payload_len) {
        // Calculate total length of the KKOS message (header + actual payload)
        uint32_t kkos_message_len = sizeof(KKOS_PacketHeader) + payload_len;

        // Prepare KKOS header
        KKOS_PacketHeader hdr;
        hdr.magic = 0x4B4B4F53; // Ensure magic is set
        hdr.version = 43;       // Ensure version is set
        hdr.packet_type = type;
        hdr.timestamp_ns = std::chrono::duration_cast<std::chrono::nanoseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count();
        ShardedCoreState* current_state = lane_a_live_ptr.load();
        hdr.frame_seq = current_state ? current_state->frame_seq : 0;
        hdr.crc32 = crc32(payload, payload_len); // CRC for the actual payload
        hdr.payload_len = payload_len;
        
        std::vector<uint8_t> ws_frame_buffer; // Declare ws_frame_buffer here
        ws_frame_buffer.reserve(2 + kkos_message_len);
        ws_frame_buffer.push_back(0x82); // FIN + Binary opcode
        ws_frame_buffer.push_back(static_cast<uint8_t>(kkos_message_len)); // Payload length

        // Construct WebSocket frame
        std::vector<uint8_t> ws_frame_buffer;
        ws_frame_buffer.reserve(2 + kkos_message_len); // WS header (2 bytes) + KKOS message

        ws_frame_buffer.push_back(0x82); // FIN + Binary
        ws_frame_buffer.push_back(static_cast<uint8_t>(kkos_message_len)); // length

        // Append KKOS header and payload
        const uint8_t* hdr_bytes = reinterpret_cast<const uint8_t*>(&hdr);
        ws_frame_buffer.insert(ws_frame_buffer.end(), hdr_bytes, hdr_bytes + sizeof(KKOS_PacketHeader));
        const uint8_t* payload_bytes = reinterpret_cast<const uint8_t*>(payload);
        ws_frame_buffer.insert(ws_frame_buffer.end(), payload_bytes, payload_bytes + payload_len);

        std::lock_guard<std::mutex> lock(ws_mtx);
        for (auto it = ws_clients.begin(); it != ws_clients.end();) {
            int sent = send(*it, reinterpret_cast<const char*>(ws_frame_buffer.data()), static_cast<int>(ws_frame_buffer.size()), 0);
            if (sent <= 0) {
                CLOSE_SOCKET(*it);
                it = ws_clients.erase(it);
            } else {
                ++it;
            }
        }
    }

    void audit_frame(uint64_t seq, const ShardedCoreState& a_state, uint64_t b_hash) {
        uint64_t a_hash = xxh::xxhash64(&a_state, sizeof(ShardedCoreState), 0);
        if (a_hash!= b_hash) {
            uint64_t target = (seq / 10) * 10;
            std::shared_lock<std::shared_mutex> lock(cache_mtx);
            auto it = snapshot_cache.find(target);
            if (it == snapshot_cache.end()) {
                std::cerr << "[CHOFE] No supernode for " << target << std::endl;
                return;
            }
            ShardedCoreState* old = lane_a_live_ptr.exchange(new ShardedCoreState(it->second));
            delete old;
            RollbackEvent ev{seq, target, a_hash, b_hash};
            broadcast(0x0002, &ev, sizeof(ev));
            std::cout << "[LANE C] Rollback " << seq << " -> " << target << std::endl;
        }
        if (seq % 10 == 0) {
            std::unique_lock<std::shared_mutex> lock(cache_mtx);
            snapshot_cache[seq] = a_state;
            if (snapshot_cache.size() > 100) snapshot_cache.erase(snapshot_cache.begin());
        }
    }
};

LaneC_RollbackController g_lane_c;

bool websocket_handshake(socket_t client) {
    std::string request;
    char buffer[2048];
    while (request.find("\r\n\r\n") == std::string::npos) {
        int result = recv(client, buffer, sizeof(buffer) - 1, 0);
        if (result <= 0) return false;
        buffer[result] = '\0';
        request.append(buffer, result);
        if (request.size() > 8192) return false;
    }

    size_t keyPos = request.find("Sec-WebSocket-Key:");
    if (keyPos == std::string::npos) return false;
    size_t lineEnd = request.find("\r\n", keyPos);
    if (lineEnd == std::string::npos) return false;

    std::string key = request.substr(keyPos + strlen("Sec-WebSocket-Key:"), lineEnd - (keyPos + strlen("Sec-WebSocket-Key:")));
    size_t start = key.find_first_not_of(" \t");
    size_t end = key.find_last_not_of(" \t\r\n");
    if (start == std::string::npos || end == std::string::npos) return false;
    key = key.substr(start, end - start + 1);

    std::string acceptKey = compute_websocket_accept(key);
    std::string response =
        "HTTP/1.1 101 Switching Protocols\r\n"
        "Upgrade: websocket\r\n"
        "Connection: Upgrade\r\n"
        "Sec-WebSocket-Accept: " + acceptKey + "\r\n\r\n";

    int sent = send(client, response.c_str(), static_cast<int>(response.size()), 0);
    return sent == static_cast<int>(response.size());
}

// ============================================================================
// SECTION 4: MAIN LOOP + WEBSOCKET SERVER
// ============================================================================
std::atomic<bool> running{true};
void sigint(int) { running = false; }

int main() {
    signal(SIGINT, sigint);
#ifdef _WIN32
    WSADATA wsa;
    if (WSAStartup(MAKEWORD(2,2), &wsa) != 0) {
        std::cerr << "WSAStartup failed.\n";
        return 1;
    }
#endif

    g_lane_c.lane_a_live_ptr = new ShardedCoreState{};
    std::thread([]() {
        uint64_t seq = 0;
        // Initialize random seed for simulation metrics
        srand(static_cast<unsigned int>(time(0)));
        while (running) {
            ShardedCoreState state = *g_lane_c.lane_a_live_ptr.load();
            state.frame_seq = seq++;
            state.state_flags = 0x01; // inoculated
            // Simulate metrics
            state.shard_metrics[0] = 0.85f + (rand() % 10) * 0.01f;
            ShardedCoreState shadow = state; // Lane B clone
            g_lane_c.audit_frame(seq, state, xxh::xxhash64(&shadow, sizeof(shadow), 0));

            CoherenceSnapshot snap{};
            snap.coherence_score = 85;
            snap.state_flags = 0x01;
            snap.lane_a_hash = xxh::xxhash64(&state, sizeof(state), 0);
            snap.lane_b_hash = xxh::xxhash64(&shadow, sizeof(shadow), 0);
            snap.active_shard_count = 8;
            g_lane_c.broadcast(0x0001, &snap, sizeof(snap));
            std::this_thread::sleep_for(std::chrono::milliseconds(16)); // ~60Hz
        }
    }).detach();

    // Minimal WS accept loop on port 8080
    socket_t server = socket(AF_INET, SOCK_STREAM, 0);
    sockaddr_in addr{AF_INET, htons(8080), INADDR_ANY};
    socket_t server = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP); // Specify IPPROTO_TCP for clarity
    socket_t server = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(8080);
    addr.sin_addr.s_addr = htonl(INADDR_ANY); // Use htonl for INADDR_ANY
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    bind(server, (sockaddr*)&addr, sizeof(addr));
    listen(server, 5);
    std::cout << "[✓] KKOS v4.3 listening on ws://localhost:8080" << std::endl;
    while (running) {
        socket_t client = accept(server, nullptr, nullptr);
        if (client == INVALID_SOCKET) continue;
        if (!websocket_handshake(client)) {
            CLOSE_SOCKET(client);
            continue;
        }
        std::lock_guard<std::mutex> lock(g_lane_c.ws_mtx);
        g_lane_c.ws_clients.push_back(client);
    }
    CLOSE_SOCKET(server);
#ifdef _WIN32
    WSACleanup(); // Cleanup Winsock resources
#endif
    return 0;
}
