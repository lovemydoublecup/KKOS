// This file has been moved to archive/kkos_v39_production.cpp for consolidation.
// kkos_v2_unified.cpp
// KKOS v2.0 / Kurfew Kult Codex — Coherence-Driven Universal Simulation Shell
// C++17 Standard Compliance, Cross-Platform Desktop & Mobile Engine Compatible

#include <iostream>
#include <string>
#include <unordered_map>
#include <functional>
#include <chrono>
#include <iomanip>
#include <fstream>
#include <random>
#include <sstream>
#include <filesystem>
#include <cmath>
#include <algorithm>
#include <vector>
#include <thread>
#include <atomic>
#include <mutex>

namespace fs = std::filesystem;

// ============================================================================
// CROSS-PLATFORM SYSTEM TIME & TELEMETRY UTILITIES
// ============================================================================

std::string currentTimestamp() {
    using clock = std::chrono::system_clock;
    auto now = clock::now();
    std::time_t t = clock::to_time_t(now);
    std::tm tm{};
#ifdef _WIN32
    localtime_s(&tm, &t);
#else
    localtime_r(&t, &tm);
#endif
    std::ostringstream oss;
    oss << std::put_time(&tm, "%Y-%m-%d %H:%M:%S");
    return oss.str();
}

std::string currentDateForLog() {
    using clock = std::chrono::system_clock;
    auto now = clock::now();
    std::time_t t = clock::to_time_t(now);
    std::tm tm{};
#ifdef _WIN32
    localtime_s(&tm, &t);
#else
    localtime_r(&t, &tm);
#endif
    std::ostringstream oss;
    oss << std::put_time(&tm, "%Y-%m-%d");
    return oss.str();
}

std::string currentDateTimeForFile() {
    using clock = std::chrono::system_clock;
    auto now = clock::now();
    std::time_t t = clock::to_time_t(now);
    std::tm tm{};
#ifdef _WIN32
    localtime_s(&tm, &t);
#else
    localtime_r(&t, &tm);
#endif
    std::ostringstream oss;
    oss << std::put_time(&tm, "%Y%m%d_%H%M%S");
    return oss.str();
}

enum class AnsiColor { RESET, RED, YELLOW, GREEN, CYAN, MAGENTA, BLUE, WHITE };

std::string colorCode(AnsiColor c) {
    switch (c) {
        case AnsiColor::RED:     return "\033[31m";
        case AnsiColor::YELLOW:  return "\033[33m";
        case AnsiColor::GREEN:   return "\033[32m";
        case AnsiColor::CYAN:    return "\033[36m";
        case AnsiColor::MAGENTA: return "\033[35m";
        case AnsiColor::BLUE:    return "\033[34m";
        case AnsiColor::WHITE:   return "\033[37m";
        case AnsiColor::RESET:
        default:                 return "\033[0m";
    }
}

void printColored(const std::string& text, AnsiColor c) {
    std::cout << colorCode(c) << text << colorCode(AnsiColor::RESET);
}

double clampDouble(double v, double lo, double hi) {
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
}

std::string toLower(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c){ return std::tolower(c); });
    return s;
}

std::string trim(const std::string& str) {
    size_t first = str.find_first_not_of(" \t\n\r");
    if (std::string::npos == first) return "";
    size_t last = str.find_last_not_of(" \t\n\r");
    return str.substr(first, (last - first + 1));
}

struct Config {
    double baseSynchronization   = 0.75;
    double baseStability         = 0.75;
    double baseSustainability    = 0.80;
    double baseRuntimeIntegrity  = 0.80;
    double baseStressLoad        = 0.15;
    double baseEntropy           = 0.15;
    double baseErrorPropagation  = 0.10;
    int collapseThreshold        = 25;
    int recoveryThreshold        = 40;
    bool kidMode                 = false;
    bool expertMode              = true;
    double sustainBoostFactor    = 1.0;

    bool enableColors            = true;
    std::string logPath          = "logs/kkos_v39.log";
    std::string codexPath        = "docs/codex.txt";
    std::string reportsDir       = "reports";
    std::string prompt           = "\nkkos> ";

    bool enableWebSocket         = false;
    int websocketPort            = 8080;
    bool websocketAuth           = false;
    std::string websocketToken   = "default_token";
    int websocketMaxArgsLength   = 256;
    std::vector<std::string> websocketAllowCommands = {"status", "coherence", "help"};

    static Config load(const std::string& path) {
        Config cfg;
        std::ifstream in(path);
        if (!in.is_open()) return cfg;

        std::string line;
        while (std::getline(in, line)) {
            line = trim(line);
            if (line.empty() || line.front() == '{' || line.front() == '}' || line.front() == '/') continue;

            auto colonPos = line.find(':');
            if (colonPos == std::string::npos) continue;

            std::string key = trim(line.substr(0, colonPos));
            std::string value = trim(line.substr(colonPos + 1));

            auto clean = [](std::string s) {
                if (!s.empty() && s.back() == ',') s.pop_back();
                if (!s.empty() && s.front() == '"' && s.back() == '"') s = s.substr(1, s.length() - 2);
                return s;
            };

            key = clean(key);
            value = clean(value);

            if (key == "baseSynchronization") cfg.baseSynchronization = std::stod(value);
            else if (key == "baseStability") cfg.baseStability = std::stod(value);
            else if (key == "baseSustainability") cfg.baseSustainability = std::stod(value);
            else if (key == "baseRuntimeIntegrity") cfg.baseRuntimeIntegrity = std::stod(value);
            else if (key == "baseStressLoad") cfg.baseStressLoad = std::stod(value);
            else if (key == "baseEntropy") cfg.baseEntropy = std::stod(value);
            else if (key == "baseErrorPropagation") cfg.baseErrorPropagation = std::stod(value);
            else if (key == "collapseThreshold") cfg.collapseThreshold = std::stoi(value);
            else if (key == "recoveryThreshold") cfg.recoveryThreshold = std::stoi(value);
            else if (key == "kidMode") cfg.kidMode = (value == "true");
            else if (key == "expertMode") cfg.expertMode = (value == "true");
            else if (key == "sustainBoostFactor") cfg.sustainBoostFactor = std::stod(value);
            else if (key == "enableColors") cfg.enableColors = (value == "true");
            else if (key == "logPath") cfg.logPath = value;
            else if (key == "codexPath") cfg.codexPath = value;
            else if (key == "reportsDir") cfg.reportsDir = value;
            else if (key == "prompt") cfg.prompt = value;
            else if (key == "enableWebSocket") cfg.enableWebSocket = (value == "true");
            else if (key == "websocketPort") cfg.websocketPort = std::stoi(value);
            else if (key == "websocketAuth") cfg.websocketAuth = (value == "true");
            else if (key == "websocketToken") cfg.websocketToken = value;
            else if (key == "websocketMaxArgsLength") cfg.websocketMaxArgsLength = std::stoi(value);
        }
        return cfg;
    }
};

struct CoherenceMetrics {
    // v3.9 Combined Metric Set - Standardized to Logic expectations
    float coherence          = 70.0f;
    float stressLoad         = 10.0f;
    float stress_load        = 10.0f;
    float sustainability     = 80.0f;
    float thermalStability   = 90.0f;
    float thermal_stability  = 90.0f;
    float synchronization    = 75.0f;

    double stability         = 0.7;
    double runtimeIntegrity  = 0.7;
    double entropy           = 0.2;
    double errorPropagation  = 0.1;
};

struct SystemState {
    bool inoculated          = false;
    bool collapsed           = false;
    bool sustaining          = false;
    CoherenceMetrics metrics;
    int coherenceScore       = 70;
};

std::string timestamp(bool fileSafe = false) {
    auto now = std::chrono::system_clock::now();
    std::time_t t = std::chrono::system_clock::to_time_t(now);
    std::tm tm{};
#ifdef _WIN32
    localtime_s(&tm, &t);
#else
    localtime_r(&t, &tm);
#endif
    std::ostringstream oss;
    if (fileSafe) {
        oss << std::put_time(&tm, "%Y%m%d_%H%M%S");
    } else {
        oss << std::put_time(&tm, "%Y-%m-%d %H:%M:%S");
    }
    return oss.str();
}

std::string filenameTimestamp() { return timestamp(true); }

void printColored(const std::string& text, AnsiColor c) {
    std::cout << colorCode(c) << text << colorCode(AnsiColor::RESET);
}

// ============================================================================
// SYSTEM STRUCTURES, METRICS, AND TELEMETRY CONFIGURATION
// ============================================================================

struct Config {
    double baseSynchronization   = 0.75;
    double baseStability         = 0.75;
    double baseSustainability    = 0.80;
    double baseRuntimeIntegrity  = 0.80;
    double baseStressLoad        = 0.15;
    double baseEntropy           = 0.15;
    double baseErrorPropagation  = 0.10;
    int collapseThreshold        = 25;
    int recoveryThreshold        = 40;
    bool kidMode                 = false;
    bool expertMode              = true;
    double sustainBoostFactor    = 1.0;
};

struct CoherenceMetrics {
    // v3.9 Combined Metric Set
    float coherence          = 70.0f;
    float stress_load        = 10.0f;
    float sustainability     = 80.0f;
    float thermal_stability  = 90.0f;
    float synchronization    = 75.0f;

    double stability         = 0.7;
    double runtimeIntegrity  = 0.7;
    double entropy           = 0.2;
    double errorPropagation  = 0.1;
};

struct SystemState {
    bool inoculated          = false;
    bool collapsed           = false;
    bool sustaining          = false;
    CoherenceMetrics metrics;
    int coherenceScore       = 70;
};

struct TelemetrySample {
    std::string timestamp;
    int coherenceScore;
    CoherenceMetrics metrics;
};

struct CodexEntry {
    std::string key;
    std::string content;
    std::string citation;
};

struct RuntimeContext {
    SystemState state;
    Config config;
    bool running = true;
    std::string logFilePath;
    std::vector<TelemetrySample> telemetryHistory;
    std::vector<CodexEntry> codexDatabase;
    std::mutex stateMutex;
};

// ============================================================================
// ENCAPSULATED CORE PROCESSOR: COHERENCE ENGINE
// ============================================================================

class CoherenceEngine {
private:
    const Config* cfg_ptr;
    std::mt19937 rng;
    std::uniform_real_distribution<double> noise;

public:
    explicit CoherenceEngine(const Config& config)
    : cfg_ptr(&config), rng(std::random_device{}()), noise(-0.03, 0.03) {}

    void initialize(SystemState& state) {
        const auto& cfg = *cfg_ptr;
        state.inoculated = true;
        state.collapsed  = false;
        state.sustaining = false;
        state.metrics.synchronization   = cfg.baseSynchronization;
        state.metrics.stability         = cfg.baseStability;
        state.metrics.sustainability    = cfg.baseSustainability;
        state.metrics.runtimeIntegrity  = cfg.baseRuntimeIntegrity;
        state.metrics.stressLoad        = cfg.baseStressLoad;
        state.metrics.stress_load       = cfg.baseStressLoad;
        state.metrics.entropy           = cfg.baseEntropy;
        state.metrics.errorPropagation  = cfg.baseErrorPropagation;
        state.coherenceScore = computeCoherence(state.metrics);
    }

    void applyStress(SystemState& state, double magnitude) {
        const auto& cfg = *cfg_ptr;
        magnitude = clampDouble(magnitude, 0.0, 1.0);
        state.metrics.stressLoad       = clampDouble(state.metrics.stressLoad + magnitude * 0.3, 0.0, 1.0);
        state.metrics.stress_load      = state.metrics.stressLoad;
        state.metrics.entropy          = clampDouble(state.metrics.entropy + magnitude * 0.25, 0.0, 1.0);
        state.metrics.errorPropagation = clampDouble(state.metrics.errorPropagation + magnitude * 0.2, 0.0, 1.0);
        state.metrics.synchronization  = clampDouble(state.metrics.synchronization - magnitude * 0.2, 0.0, 1.0);
        state.metrics.stability        = clampDouble(state.metrics.stability - magnitude * 0.25, 0.0, 1.0);
        state.metrics.sustainability   = clampDouble(state.metrics.sustainability - magnitude * 0.2, 0.0, 1.0);
        state.metrics.runtimeIntegrity = clampDouble(state.metrics.runtimeIntegrity - magnitude * 0.2, 0.0, 1.0);
        state.coherenceScore = computeCoherence(state.metrics);
        if (state.coherenceScore < cfg.collapseThreshold) {
            state.collapsed = true;
        }
    }

    void sustain(SystemState& state, double effort) {
        const auto& cfg = *cfg_ptr;
        effort = clampDouble(effort * cfg.sustainBoostFactor, 0.0, 1.0);
        state.sustaining = true;
        state.metrics.stressLoad       = clampDouble(state.metrics.stressLoad - effort * 0.25, 0.0, 1.0);
        state.metrics.stress_load      = state.metrics.stressLoad;
        state.metrics.entropy          = clampDouble(state.metrics.entropy - effort * 0.2, 0.0, 1.0);
        state.metrics.errorPropagation = clampDouble(state.metrics.errorPropagation - effort * 0.2, 0.0, 1.0);
        state.metrics.synchronization  = clampDouble(state.metrics.synchronization + effort * 0.25, 0.0, 1.0);
        state.metrics.stability        = clampDouble(state.metrics.stability + effort * 0.25, 0.0, 1.0);
        state.metrics.sustainability   = clampDouble(state.metrics.sustainability + effort * 0.3, 0.0, 1.0);
        state.metrics.runtimeIntegrity = clampDouble(state.metrics.runtimeIntegrity + effort * 0.25, 0.0, 1.0);
        state.coherenceScore = computeCoherence(state.metrics);
        if (state.coherenceScore >= cfg.recoveryThreshold) {
            state.collapsed = false;
        }
    }

    void reset(SystemState& state) {
        state = SystemState{};
    }

    int computeCoherence(const CoherenceMetrics& m) {
        double positive = m.synchronization + m.stability + m.sustainability + m.runtimeIntegrity;
        double negative = m.stressLoad + m.entropy + m.errorPropagation;
        double base = positive - negative + noise(rng);
        base = clampDouble(base, -2.0, 2.0);
        double normalized = (base + 2.0) / 4.0;
        return std::clamp(static_cast<int>(std::round(normalized * 100.0)), 0, 100);
    }
};

#ifdef _WIN32
using socket_t = SOCKET;
const socket_t invalid_socket = INVALID_SOCKET;
#else
using socket_t = int;
const socket_t invalid_socket = -1;
#endif

static void closeSocket(socket_t socket) {
#ifdef _WIN32
    closesocket(socket);
#else
    close(socket);
#endif
}

static bool isWouldBlock() {
#ifdef _WIN32
    return WSAGetLastError() == WSAEWOULDBLOCK;
#else
    return errno == EWOULDBLOCK || errno == EAGAIN;
#endif
}

static void networkStartup() {
#ifdef _WIN32
    WSADATA wsaData;
    WSAStartup(MAKEWORD(2, 2), &wsaData);
#endif
}

static void networkCleanup() {
#ifdef _WIN32
    WSACleanup();
#endif
}

static std::string base64Encode(const std::string& data) {
    static const char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    std::string result;
    int val = 0, valb = -6;
    for (unsigned char c : data) {
        val = (val << 8) + c;
        valb += 8;
        while (valb >= 0) {
            result.push_back(table[(val >> valb) & 0x3F]);
            valb -= 6;
        }
    }
    if (valb > -6) {
        result.push_back(table[((val << 8) >> (valb + 8)) & 0x3F]);
    }
    while (result.size() % 4) {
        result.push_back('=');
    }
    return result;
}

static std::string sha1HashBytes(const std::string& input) {
    auto rotl = [](uint32_t v, int s) { return (v << s) | (v >> (32 - s)); };
    std::vector<uint8_t> m(input.begin(), input.end());
    uint64_t bits = static_cast<uint64_t>(m.size()) * 8;
    m.push_back(0x80);
    while (m.size() % 64 != 56) m.push_back(0x00);
    for (int i = 7; i >= 0; --i) m.push_back(static_cast<uint8_t>(bits >> (i * 8)));
    uint32_t h[5] = { 0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0 };
    for (size_t offset = 0; offset < m.size(); offset += 64) {
        uint32_t w[80] = { 0 };
        for (int i = 0; i < 16; ++i) {
            w[i] = (static_cast<uint32_t>(m[offset + i * 4]) << 24) | (static_cast<uint32_t>(m[offset + i * 4 + 1]) << 16) |
                   (static_cast<uint32_t>(m[offset + i * 4 + 2]) << 8) | (static_cast<uint32_t>(m[offset + i * 4 + 3]));
        }
        for (int i = 16; i < 80; ++i) w[i] = rotl(w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16], 1);
        uint32_t a = h[0], b = h[1], c = h[2], d = h[3], e = h[4];
        for (int i = 0; i < 80; ++i) {
            uint32_t f, k;
            if (i < 20) { f = (b & c) | ((~b) & d); k = 0x5A827999; }
            else if (i < 40) { f = b ^ c ^ d; k = 0x6ED9EBA1; }
            else if (i < 60) { f = (b & c) | (b & d) | (c & d); k = 0x8F1BBCDC; }
            else { f = b ^ c ^ d; k = 0xCA62C1D6; }
            uint32_t temp = rotl(a, 5) + f + e + k + w[i];
            e = d; d = c; c = rotl(b, 30); b = a; a = temp;
        }
        h[0] += a; h[1] += b; h[2] += c; h[3] += d; h[4] += e;
    }
    std::string out;
    for (uint32_t val : h) { for (int i = 3; i >= 0; --i) out.push_back(static_cast<char>(val >> (i * 8))); }
    return out;
}

static std::string makeWebSocketAccept(const std::string& key) {
    const std::string magic = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
    auto raw = sha1HashBytes(key + magic);
    return base64Encode(raw);
}

static std::string makeWebSocketFrame(const std::string& payload) {
    std::string frame;
    frame.push_back(static_cast<char>(0x81));
    size_t length = payload.size();
    if (length <= 125) {
        frame.push_back(static_cast<char>(length));
    } else if (length <= 65535) {
        frame.push_back(126);
        frame.push_back(static_cast<char>((length >> 8) & 0xFF));
        frame.push_back(static_cast<char>(length & 0xFF));
    } else {
        frame.push_back(127);
        for (int i = 7; i >= 0; --i) {
            frame.push_back(static_cast<char>((length >> (8 * i)) & 0xFF));
        }
    }
    frame += payload;
    return frame;
}

class WebSocketServer {
public:
    explicit WebSocketServer(int port)
        : port_(port), active_(false), listener_(invalid_socket), client_(invalid_socket) {}

    ~WebSocketServer() {
        stop();
    }

    bool start() {
        networkStartup();
        listener_ = ::socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
        if (listener_ == invalid_socket) {
            return false;
        }

        int opt = 1;
        setsockopt(listener_, SOL_SOCKET, SO_REUSEADDR, reinterpret_cast<char*>(&opt), sizeof(opt));

        sockaddr_in addr{};
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = htonl(INADDR_ANY);
        addr.sin_port = htons(static_cast<uint16_t>(port_));

        if (bind(listener_, reinterpret_cast<sockaddr*>(&addr), sizeof(addr)) != 0) {
            closeSocket(listener_);
            listener_ = invalid_socket;
            return false;
        }

        if (listen(listener_, 1) != 0) {
            closeSocket(listener_);
            listener_ = invalid_socket;
            return false;
        }

        active_ = true;
        thread_ = std::thread(&WebSocketServer::run, this);
        return true;
    }

    void stop() {
        active_ = false;
        if (listener_ != invalid_socket) {
            closeSocket(listener_);
            listener_ = invalid_socket;
        }
        closeClient();
        if (thread_.joinable()) {
            thread_.join();
        }
        networkCleanup();
    }

    void broadcast(const std::string& message) {
        std::lock_guard<std::mutex> lock(clientMutex_);
        if (client_ == invalid_socket) {
            return;
        }
        std::string frame = makeWebSocketFrame(message);
        sendAll(client_, frame.data(), frame.size());
    }

    void sendText(const std::string& message) {
        std::lock_guard<std::mutex> lock(clientMutex_);
        if (client_ == invalid_socket) {
            return;
        }
        std::string frame = makeWebSocketFrame(message);
        sendAll(client_, frame.data(), frame.size());
    }

    void setMessageHandler(const std::function<void(const std::string&)>& handler) {
        onMessage_ = handler;
    }

private:
    bool receiveBytes(socket_t sock, char* buffer, size_t size) {
        size_t total = 0;
        while (total < size) {
            int result = recv(sock, buffer + total, static_cast<int>(size - total), 0);
            if (result > 0) {
                total += static_cast<size_t>(result);
                continue;
            }
            if (result == 0) {
                return false;
            }
            if (isWouldBlock()) {
                std::this_thread::sleep_for(std::chrono::milliseconds(10));
                continue;
            }
            return false;
        }
        return true;
    }

    bool tryReadWebSocketFrame(socket_t sock, std::string& payload) {
        uint8_t header[2];
        int peeked = recv(sock, reinterpret_cast<char*>(header), 2, MSG_PEEK);
        if (peeked == 0) {
            return false;
        }
        if (peeked < 0) {
            if (isWouldBlock()) {
                return false;
            }
            return false;
        }
        if (peeked < 2) {
            return false;
        }

        uint8_t opcode = header[0] & 0x0F;
        if (opcode == 0x8) {
            return false;
        }

        if (!receiveBytes(sock, reinterpret_cast<char*>(header), 2)) {
            return false;
        }

        uint8_t secondByte = header[1];
        bool masked = (secondByte & 0x80) != 0;
        uint64_t length = secondByte & 0x7F;
        if (length == 126) {
            uint8_t ext[2];
            if (!receiveBytes(sock, reinterpret_cast<char*>(ext), 2)) {
                return false;
            }
            length = (static_cast<uint64_t>(ext[0]) << 8) | ext[1];
        } else if (length == 127) {
            uint8_t ext[8];
            if (!receiveBytes(sock, reinterpret_cast<char*>(ext), 8)) {
                return false;
            }
            length = 0;
            for (int i = 0; i < 8; ++i) {
                length = (length << 8) | ext[i];
            }
        }

        uint8_t maskKey[4] = {0};
        if (masked) {
            if (!receiveBytes(sock, reinterpret_cast<char*>(maskKey), 4)) {
                return false;
            }
        }

        payload.resize(length);
        if (length > 0) {
            if (!receiveBytes(sock, payload.data(), static_cast<size_t>(length))) {
                return false;
            }
        }

        if (masked) {
            for (size_t i = 0; i < payload.size(); ++i) {
                payload[i] ^= maskKey[i % 4];
            }
        }

        return true;
    }

    void run() {
        while (active_) {
            sockaddr_in clientAddr{};
            socklen_t addrLen = sizeof(clientAddr);
            socket_t clientSocket = accept(listener_, reinterpret_cast<sockaddr*>(&clientAddr), &addrLen);
            if (clientSocket == invalid_socket) {
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
                continue;
            }

            std::string handshake;
            handshake.reserve(1024);
            char buffer[1024];
            int received = recv(clientSocket, buffer, sizeof(buffer) - 1, 0);
            if (received <= 0) {
                closeSocket(clientSocket);
                continue;
            }
            buffer[received] = '\0';
            handshake = buffer;

            auto key = extractWebSocketKey(handshake);
            if (key.empty()) {
                closeSocket(clientSocket);
                continue;
            }

            auto acceptValue = makeWebSocketAccept(key);
            std::ostringstream response;
            response << "HTTP/1.1 101 Switching Protocols\r\n"
                     << "Upgrade: websocket\r\n"
                     << "Connection: Upgrade\r\n"
                     << "Sec-WebSocket-Accept: " << acceptValue << "\r\n\r\n";
            std::string responseText = response.str();
            sendAll(clientSocket, responseText.data(), responseText.size());
            setNonBlocking(clientSocket);

            {
                std::lock_guard<std::mutex> lock(clientMutex_);
                closeClient();
                client_ = clientSocket;
            }

            while (active_ && client_ != invalid_socket) {
                std::string payload;
                if (tryReadWebSocketFrame(clientSocket, payload)) {
                    if (!payload.empty() && onMessage_) {
                        onMessage_(payload);
                    }
                }
                if (!active_ || client_ == invalid_socket) {
                    break;
                }
                std::this_thread::sleep_for(std::chrono::milliseconds(50));
            }
        }
    }

    std::string extractWebSocketKey(const std::string& request) const {
        std::istringstream stream(request);
        std::string line;
        while (std::getline(stream, line)) {
            auto colon = line.find(':');
            if (colon == std::string::npos) {
                continue;
            }
            auto name = toLower(trim(line.substr(0, colon)));
            if (name == "sec-websocket-key") {
                return trim(line.substr(colon + 1));
            }
        }
        return {};
    }

    void setNonBlocking(socket_t sock) {
#ifdef _WIN32
        u_long mode = 1;
        ioctlsocket(sock, FIONBIO, &mode);
#else
        fcntl(sock, F_SETFL, O_NONBLOCK);
#endif
    }

    void closeClient() {
        if (client_ != invalid_socket) {
            closeSocket(client_);
            client_ = invalid_socket;
        }
    }

    bool sendAll(socket_t socket, const char* data, size_t size) {
        size_t sent = 0;
        while (sent < size) {
            int result = ::send(socket, data + sent, static_cast<int>(size - sent), 0);
            if (result <= 0) {
                if (isWouldBlock()) {
                    std::this_thread::sleep_for(std::chrono::milliseconds(10));
                    continue;
                }
                closeClient();
                return false;
            }
            sent += result;
        }
        return true;
    }

    int port_;
    std::atomic<bool> active_;
    socket_t listener_;
    socket_t client_;
    std::thread thread_;
    std::mutex clientMutex_;
    std::function<void(const std::string&)> onMessage_;
};

class LogManager {
public:
    explicit LogManager(const fs::path& path)
        : path_(path) {
        if (auto dir = path_.parent_path(); !dir.empty()) {
            fs::create_directories(dir);
        }
        stream_.open(path_, std::ios::app);
        if (stream_) {
            stream_ << "[" << currentTimestamp() << "] Session started\n";
        }
    }

    void append(const std::string& message) {
        if (!stream_) return;
        stream_ << "[" << currentTimestamp() << "] " << message << "\n";
    }

private:
    fs::path path_;
    std::ofstream stream_;
};

class CodexIndex {
public:
    bool load(const fs::path& path) {
        std::ifstream stream(path);
        if (!stream) {
            return false;
        }

        std::string line;
        while (std::getline(stream, line)) {
            if (!trim(line).empty()) {
                entries_.push_back(line);
            }
        }

        return true;
    }

    std::vector<std::string> search(const std::string& query) const {
        std::vector<std::string> results;
        auto needle = toLower(query);

        for (const auto& entry : entries_) {
            if (toLower(entry).find(needle) != std::string::npos) {
                results.push_back(entry);
            }
        }

        return results;
    }

private:
    std::vector<std::string> entries_;
};

class CoherenceEngine {
public:
    explicit CoherenceEngine(const CoherenceMetrics& metrics = {})
        : metrics_(metrics) {}

    const CoherenceMetrics& metrics() const {
        return metrics_;
    }

    void inoculate() {
        metrics_.coherence = 94.0f;
        metrics_.stress_load = 5.0f;
        metrics_.sustainability = std::min(100.0f, metrics_.sustainability + 2.0f);
    }

    void collapse() {
        metrics_.stress_load = std::min(100.0f, metrics_.stress_load + 35.0f);
        metrics_.coherence = std::max(0.0f, metrics_.coherence - 28.0f);
        metrics_.thermal_stability = std::max(0.0f, metrics_.thermal_stability - 12.0f);
    }

    void sustain() {
        metrics_.coherence = std::min(100.0f, metrics_.coherence + 10.0f);
        metrics_.sustainability = std::min(100.0f, metrics_.sustainability + 5.0f);
        metrics_.stress_load = std::max(0.0f, metrics_.stress_load - 10.0f);
    }

    void reset() {
        metrics_ = CoherenceMetrics();
    }

    std::string state() const {
        if (metrics_.coherence >= 85.0f) {
            return "STABLE";
        }
        if (metrics_.coherence >= 60.0f) {
            return "DEGRADED";
        }
        return "CRITICAL";
    }

private:
    CoherenceMetrics metrics_;
};

struct KKOSState {
    bool gate_open = false;
    bool threshold_clean = false;
    bool kiln_active = false;
    bool crypt_synced = false;
    bool page1 = false;
    bool mycelial_core_online = false;
    bool quantum_mesh_locked = true;
    int mesh_peers = 4;
    float damping_capacity = 0.88f;
    float conductance_ms = 0.8f;
    CoherenceEngine engine;
};

namespace ansi {
    inline bool enabled = true;
    const char* RESET = "\x1b[0m";
    const char* RED = "\x1b[31m";
    const char* GREEN = "\x1b[32m";
    const char* YELLOW = "\x1b[33m";
    const char* CYAN = "\x1b[36m";

    inline const char* code(const char* value) {
        return enabled ? value : "";
    }
}

static void enableAnsiOnWindows() {
#ifdef _WIN32
    HANDLE handle = GetStdHandle(STD_OUTPUT_HANDLE);
    if (handle == INVALID_HANDLE_VALUE) {
        return;
    }

    DWORD mode = 0;
    if (!GetConsoleMode(handle, &mode)) {
        return;
    }

    SetConsoleMode(handle, mode | ENABLE_VIRTUAL_TERMINAL_PROCESSING);
#endif
}

static std::string boolText(bool value) {
    return value ? "ON" : "OFF";
}

static void print_banner() {
    std::cout << ansi::code(ansi::CYAN);
    std::cout << R"(

██╗  ██╗██╗  ██╗ ██████╗ ███████╗
██║ ██╔╝██║ ██╔╝██╔═══██╗██╔════╝
█████╔╝ █████╔╝ ██║   ██║███████╗
██╔═██╗ ██╔═██╗ ██║   ██║╚════██║
██║  ██╗██║  ██╗╚██████╔╝███████║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝

KKOS v2.0 :: Unified Simulation Framework
)";
    std::cout << ansi::code(ansi::RESET) << "\n";
}

static void print_status(const KKOSState& state) {
    std::cout << "\n--- KKOS STATUS ---\n";
    std::cout << "Gate Open:            " << boolText(state.gate_open) << "\n";
    std::cout << "Threshold Clean:      " << boolText(state.threshold_clean) << "\n";
    std::cout << "Kiln Active:          " << boolText(state.kiln_active) << "\n";
    std::cout << "Crypt Synced:         " << boolText(state.crypt_synced) << "\n";
    std::cout << "Mycelial Core:        " << boolText(state.mycelial_core_online) << "\n";
    std::cout << "Quantum Mesh Locked:  " << boolText(state.quantum_mesh_locked) << "\n";
    std::cout << "Mesh Peers:           " << state.mesh_peers << "\n";
    std::cout << "Conductance (ms):     " << state.conductance_ms << "\n";
    std::cout << "Damping Capacity:     " << state.damping_capacity * 100 << "%\n";
    std::cout << "Coherence:            " << state.engine.metrics().coherence << "\n";
    std::cout << "Sustainability:       " << state.engine.metrics().sustainability << "\n";
    std::cout << "Stress Load:          " << state.engine.metrics().stress_load << "\n";
    std::cout << "Synchronization:      " << state.engine.metrics().synchronization << "\n";
    std::cout << "Thermal Stability:    " << state.engine.metrics().thermal_stability << "\n";
    std::cout << "----------------------\n\n";
}

static void print_coherence(const CoherenceEngine& engine) {
    std::cout << "\n[ COHERENCE ENGINE ]\n";
    std::cout << "System coherence score: "
              << std::fixed << std::setprecision(1)
              << engine.metrics().coherence << "/100\n";
    std::cout << "State: " << engine.state() << "\n";
}

static std::string escapeJson(const std::string& value) {
    std::ostringstream escaped;
    for (char c : value) {
        switch (c) {
            case '"': escaped << "\\\""; break;
            case '\\': escaped << "\\\\"; break;
            case '\b': escaped << "\\b"; break;
            case '\f': escaped << "\\f"; break;
            case '\n': escaped << "\\n"; break;
            case '\r': escaped << "\\r"; break;
            case '\t': escaped << "\\t"; break;
            default: escaped << c; break;
        }
    }
    return escaped.str();
}

static std::string serializeTelemetry(const KKOSState& state) {
    std::ostringstream json;
    json << "{\n";
    json << "  \"timestamp\": \"" << currentTimestamp() << "\",\n";
    json << "  \"gate_open\": " << (state.gate_open ? "true" : "false") << ",\n";
    json << "  \"threshold_clean\": " << (state.threshold_clean ? "true" : "false") << ",\n";
    json << "  \"kiln_active\": " << (state.kiln_active ? "true" : "false") << ",\n";
    json << "  \"crypt_synced\": " << (state.crypt_synced ? "true" : "false") << ",\n";
    json << "  \"mycelial_core_online\": " << (state.mycelial_core_online ? "true" : "false") << ",\n";
    json << "  \"quantum_mesh_locked\": " << (state.quantum_mesh_locked ? "true" : "false") << ",\n";
    json << "  \"mesh_peers\": " << state.mesh_peers << ",\n";
    json << "  \"damping_capacity\": " << state.damping_capacity << ",\n";
    json << "  \"conductance_ms\": " << state.conductance_ms << ",\n";
    json << "  \"coherence\": " << state.engine.metrics().coherence << ",\n";
    json << "  \"sustainability\": " << state.engine.metrics().sustainability << ",\n";
    json << "  \"stress_load\": " << state.engine.metrics().stress_load << ",\n";
    json << "  \"synchronization\": " << state.engine.metrics().synchronization << ",\n";
    json << "  \"thermal_stability\": " << state.engine.metrics().thermal_stability << "\n";
    json << "}";
    return json.str();
}

static std::string serializeStatusJson(const KKOSState& state) {
    std::ostringstream json;
    json << "{\n";
    json << "  \"timestamp\": \"" << currentTimestamp() << "\",\n";
    json << "  \"gate_open\": " << (state.gate_open ? "true" : "false") << ",\n";
    json << "  \"threshold_clean\": " << (state.threshold_clean ? "true" : "false") << ",\n";
    json << "  \"kiln_active\": " << (state.kiln_active ? "true" : "false") << ",\n";
    json << "  \"crypt_synced\": " << (state.crypt_synced ? "true" : "false") << ",\n";
    json << "  \"mycelial_core_online\": " << (state.mycelial_core_online ? "true" : "false") << ",\n";
    json << "  \"quantum_mesh_locked\": " << (state.quantum_mesh_locked ? "true" : "false") << ",\n";
    json << "  \"mesh_peers\": " << state.mesh_peers << ",\n";
    json << "  \"damping_capacity\": " << state.damping_capacity << ",\n";
    json << "  \"conductance_ms\": " << state.conductance_ms << ",\n";
    json << "  \"coherence\": " << state.engine.metrics().coherence << ",\n";
    json << "  \"sustainability\": " << state.engine.metrics().sustainability << ",\n";
    json << "  \"stress_load\": " << state.engine.metrics().stress_load << ",\n";
    json << "  \"synchronization\": " << state.engine.metrics().synchronization << ",\n";
    json << "  \"thermal_stability\": " << state.engine.metrics().thermal_stability << "\n";
    json << "}";
    return json.str();
}

static std::string serializeGraphCsv(const KKOSState& state) {
    std::ostringstream csv;
    csv << "timestamp,coherence,sustainability,stress_load,synchronization,thermal_stability\n";
    csv << currentTimestamp() << ","
        << state.engine.metrics().coherence << ","
        << state.engine.metrics().sustainability << ","
        << state.engine.metrics().stress_load << ","
        << state.engine.metrics().synchronization << ","
        << state.engine.metrics().thermal_stability << "\n";
    return csv.str();
}

static std::string extractJsonStringValue(const std::string& payload, const std::string& key) {
    auto pos = payload.find('"' + key + '"');
    if (pos == std::string::npos) {
        return {};
    }
    pos = payload.find(':', pos);
    if (pos == std::string::npos) {
        return {};
    }
    pos = payload.find_first_of("\"", pos + 1);
    if (pos == std::string::npos) {
        return {};
    }

    std::string result;
    for (size_t i = pos + 1; i < payload.size(); ++i) {
        char c = payload[i];
        if (c == '\\' && i + 1 < payload.size()) {
            result.push_back(payload[++i]);
        } else if (c == '"') {
            break;
        } else {
            result.push_back(c);
        }
    }
    return result;
}

static bool parseInboundCommand(const std::string& payload, std::string& command, std::string& args, std::string& token, std::string& error) {
    command = extractJsonStringValue(payload, "command");
    if (command.empty()) {
        error = "missing 'command' field";
        return false;
    }
    args = extractJsonStringValue(payload, "args");
    token = extractJsonStringValue(payload, "token");
    return true;
}

static std::string makeCommandResultJson(const std::string& command, const std::string& output, float coherence) {
    std::ostringstream json;
    json << "{\"type\":\"command_result\",\"command\":\"" << escapeJson(command) << "\",";
    json << "\"output\":\"" << escapeJson(output) << "\",";
    json << "\"coherence\":" << coherence << "}";
    return json.str();
}

static std::string processLine(const std::string& line,
                               const std::unordered_map<std::string, std::function<void(const std::string&)>>& commands,
                               std::mutex& ioMutex,
                               std::mutex& stateMutex) {
    std::lock_guard<std::mutex> iolock(ioMutex);
    std::lock_guard<std::mutex> stlock(stateMutex);

    std::streambuf* oldBuf = std::cout.rdbuf();
    std::ostringstream capture;
    std::cout.rdbuf(capture.rdbuf());

    std::string command;
    std::string arguments;
    std::istringstream parser(line);
    parser >> command;
    std::getline(parser, arguments);
    arguments = trim(arguments);

    auto it = commands.find(command);
    if (it != commands.end()) {
        it->second(arguments);
    } else {
        std::cout << "Unknown command." << std::endl;
    }

    std::cout.rdbuf(oldBuf);
    return capture.str();
}

int main() {
    Config config = Config::load("config.json");
    ansi::enabled = config.enableColors;
    enableAnsiOnWindows();

    LogManager logger(config.logPath);
    logger.append("Application started");

    CodexIndex codex;
    if (!codex.load(config.codexPath)) {
        logger.append("Codex file not found: " + config.codexPath);
    }

    KKOSState state;
    bool running = true;
    std::mutex ioMutex;
    std::mutex stateMutex;

    WebSocketServer wsServer(config.websocketPort);
    if (config.enableWebSocket) {
        if (wsServer.start()) {
            std::cout << "WebSocket server listening on port " << config.websocketPort << "\n";
            logger.append("WebSocket server started on port " + std::to_string(config.websocketPort));
        } else {
            std::cout << "WebSocket server failed to start on port " << config.websocketPort << "\n";
            logger.append("WebSocket server failed to start on port " + std::to_string(config.websocketPort));
        }
    }

    std::unordered_map<std::string, std::function<void(const std::string&)>> commands;

    commands["help"] = [&](const std::string&) {
        std::cout << "\nCommands:\n";
        std::cout << "  help\n";
        std::cout << "  inoculate\n";
        std::cout << "  collapse\n";
        std::cout << "  status\n";
        std::cout << "  status --json\n";
        std::cout << "  coherence\n";
        std::cout << "  sustain\n";
        std::cout << "  reset\n";
        std::cout << "  codex <term>\n";
        std::cout << "  export telemetry\n";
        std::cout << "  export graph\n";
        std::cout << "  exit\n\n";
    };

    commands["inoculate"] = [&](const std::string&) {
        state.page1 = true;
        state.mycelial_core_online = true;
        state.gate_open = true;
        state.threshold_clean = true;
        state.kiln_active = true;
        state.crypt_synced = true;
        state.engine.inoculate();

        std::cout << "\n" << ansi::code(ansi::GREEN);
        std::cout << "[ INOCULATE ] Unified pipeline online\n";
        std::cout << "[ GATE ] Access validated\n";
        std::cout << "[ THRESHOLD ] Input sanitized\n";
        std::cout << "[ KILN ] Runtime active\n";
        std::cout << "[ CRYPT ] Persistence synchronized\n";
        std::cout << "[ COHERENCE ] Stable at " << state.engine.metrics().coherence << "/100\n";
        std::cout << ansi::code(ansi::RESET) << "\n";
        logger.append("Executed inoculate");
        if (config.enableWebSocket) {
            wsServer.broadcast(serializeStatusJson(state));
        }
    };

    commands["collapse"] = [&](const std::string&) {
        std::cout << "\n[ EVENT ] Grid instability simulation initiated\n";
        std::this_thread::sleep_for(std::chrono::milliseconds(300));
        state.engine.collapse();

        std::cout << "[ LOAD ] Stress increased\n";
        std::cout << "[ RESPONSE ] Damping active at 88%\n";
        std::cout << "[ STATUS ] Mesh maintained\n";
        if (state.engine.metrics().coherence < 50.0f) {
            std::cout << ansi::code(ansi::YELLOW) << "[ WARNING ] Coherence approaching failure threshold\n" << ansi::code(ansi::RESET);
        }
        std::cout << "\n";
        logger.append("Executed collapse");
        if (config.enableWebSocket) {
            wsServer.broadcast(serializeStatusJson(state));
        }
    };

    commands["status"] = [&](const std::string& args) {
        if (args == "--json") {
            std::cout << serializeStatusJson(state) << "\n";
            logger.append("Displayed status as JSON");
        } else {
            print_status(state);
            logger.append("Displayed status");
        }
        if (config.enableWebSocket) {
            wsServer.broadcast(serializeStatusJson(state));
        }
    };

    commands["coherence"] = [&](const std::string&) {
        print_coherence(state.engine);
        logger.append("Displayed coherence");
    };

    commands["sustain"] = [&](const std::string&) {
        std::cout << "\n[ SOLARPUNK ] Regenerative recovery protocol active\n";
        state.engine.sustain();
        std::cout << "[ RECOVERY ] Coherence restored\n\n";
        logger.append("Executed sustain");
        if (config.enableWebSocket) {
            wsServer.broadcast(serializeStatusJson(state));
        }
    };

    commands["reset"] = [&](const std::string&) {
        state = KKOSState();
        std::cout << "\n[ RESET ] System returned to PAGE-0\n\n";
        logger.append("System reset");
        if (config.enableWebSocket) {
            wsServer.broadcast(serializeStatusJson(state));
        }
    };

    commands["codex"] = [&](const std::string& query) {
        if (query.empty()) {
            std::cout << "Usage: codex <search term>\n";
            return;
        }

        auto results = codex.search(query);
        if (results.empty()) {
            std::cout << "No codex entries matched '" << query << "'.\n";
        } else {
            std::cout << "Found " << results.size() << " codex entries for '" << query << "':\n";
            for (size_t i = 0; i < std::min(results.size(), size_t(8)); ++i) {
                std::cout << "  " << results[i] << "\n";
            }
            if (results.size() > 8) {
                std::cout << "  ...and " << (results.size() - 8) << " more entries.\n";
            }
        }
        logger.append("Searched codex: " + query);
    };

    commands["export"] = [&](const std::string& argument) {
        if (argument == "telemetry" || argument == "report") {
            fs::create_directories(config.reportsDir);
            auto outputPath = fs::path(config.reportsDir) / ("telemetry_" + filenameTimestamp() + ".json");
            std::ofstream out(outputPath);
            if (!out) {
                std::cout << "Failed to write telemetry report.\n";
                return;
            }

            out << serializeTelemetry(state);
            out.close();

            std::cout << "Telemetry report written to " << outputPath.string() << "\n";
            logger.append("Exported telemetry report: " + outputPath.string());
            return;
        }

        if (argument == "graph") {
            fs::create_directories(config.reportsDir);
            auto outputPath = fs::path(config.reportsDir) / ("coherence_" + filenameTimestamp() + ".csv");
            std::ofstream out(outputPath);
            if (!out) {
                std::cout << "Failed to write graph report.\n";
                return;
            }

            out << serializeGraphCsv(state);
            out.close();

            std::cout << "Graph report written to " << outputPath.string() << "\n";
            logger.append("Exported graph report: " + outputPath.string());
            return;
        }

        std::cout << "Usage: export telemetry | export graph\n";
    };

    commands["exit"] = [&](const std::string&) {
        std::cout << "\nDecommissioning KKOS simulation.\n";
        running = false;
        logger.append("Exiting application");
    };

    wsServer.setMessageHandler([&](const std::string& payload) {
        std::string command;
        std::string args;
        std::string token;
        std::string error;
        if (!parseInboundCommand(payload, command, args, token, error)) {
            wsServer.sendText("{\"type\":\"error\",\"msg\":\"" + escapeJson(error) + "\"}");
            return;
        }

        if (config.websocketAuth && token != config.websocketToken) {
            wsServer.sendText("{\"type\":\"error\",\"msg\":\"invalid websocket token\"}");
            return;
        }

        if (args.size() > static_cast<size_t>(config.websocketMaxArgsLength)) {
            wsServer.sendText("{\"type\":\"error\",\"msg\":\"args too long\"}");
            return;
        }

        if (!config.websocketAllowCommands.empty() &&
            std::find(config.websocketAllowCommands.begin(), config.websocketAllowCommands.end(), command) == config.websocketAllowCommands.end()) {
            wsServer.sendText("{\"type\":\"error\",\"msg\":\"command not allowed via WebSocket\"}");
            return;
        }

        std::string line = command;
        if (!args.empty()) {
            line += " " + args;
        }

        std::string output = processLine(line, commands, ioMutex, stateMutex);
        if (config.enableWebSocket) {
            wsServer.broadcast(serializeStatusJson(state));
        }

        std::string response = makeCommandResultJson(command, output, state.engine.metrics().coherence);
        wsServer.sendText(response);
    });

    print_banner();
    std::cout << "Type 'help' for commands.\n";

    while (running) {
        std::cout << config.prompt;
        std::string line;
        if (!std::getline(std::cin, line)) {
            break;
        }

        line = trim(line);
        if (line.empty()) {
            continue;
        }

        std::istringstream parser(line);
        std::string command;
        parser >> command;
        std::string arguments;
        std::getline(parser, arguments);
        arguments = trim(arguments);

        auto it = commands.find(command);
        if (it != commands.end()) {
            std::lock_guard<std::mutex> ioLock(ioMutex);
            std::lock_guard<std::mutex> stateLock(stateMutex);
            it->second(arguments);
            if (command != "exit") {
                logger.append("Command: " + line);
            }
        } else {
            std::lock_guard<std::mutex> ioLock(ioMutex);
            std::cout << ansi::code(ansi::YELLOW) << "Unknown command." << ansi::code(ansi::RESET) << "\n";
            logger.append("Unknown command: " + line);
        }
    }

    return 0;
}
