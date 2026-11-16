// ============================================================================
// KKOS v5.2.0 UNIFIED // PERISTYLE KERNEL // OPEN SOURCE DAW ENGINE
// High-Performance Optimized for Acer Nitro V 15 (i5-13420H Raptor Lake)
// System: LOVEMYDOUBLECUP // OS: Windows 11 Build 26200
// ============================================================================

#include "raylib.h" // Include raylib first

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN // NOGDI and NOUSER are already defined in c_cpp_properties.json
#include <windows.h>
#include <processthreadsapi.h>
#include <conio.h>

// Explicitly undefine common conflicts if they leak through
#undef Rectangle
#undef CloseWindow
#undef ShowCursor
#endif

#include <iostream>
#include <string>
#include <unordered_map>
#include <functional>
#include <chrono>
#include <iomanip>
#include <fstream>
#include <thread>
#include <queue>
#include <random>
#include <sstream>
#include <filesystem>
#include <cmath>
#include <algorithm>
#include <vector>
#include <memory>
#include <cctype>
#include <condition_variable>
#include <atomic>
#include <mutex>

namespace fs = std::filesystem;

#ifndef KKOS_VERSION_STR
#define KKOS_VERSION_STR "5.2.0"
#endif

// ============================================================================
// ANSI / MUTEX / UTILS (Moved for visibility)
// ============================================================================
enum class AnsiColor { AnsRESET, AnsRED, AnsYELLOW, AnsGREEN, AnsCYAN, AnsMAGENTA, AnsBLUE, AnsWHITE };
static std::recursive_mutex consoleMutex;

std::string colorCode(AnsiColor c) {
    switch (c) {
        case AnsiColor::AnsRED:     return "\033[31m";
        case AnsiColor::AnsYELLOW:  return "\033[33m";
        case AnsiColor::AnsGREEN:   return "\033[32m";
        case AnsiColor::AnsRESET:   return "\033[0m";
        case AnsiColor::AnsCYAN:    return "\033[36m";
        case AnsiColor::AnsMAGENTA: return "\033[35m";
        case AnsiColor::AnsBLUE:    return "\033[34m";
        case AnsiColor::AnsWHITE:   return "\033[37m";
        default:                    return "\033[0m";
    }
}

// ============================================================================
// NATIVE XXHASH64 INTEGRATION (Unified from v4.3 Sharded)
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
        } else { h64 = seed + PRIME64_5; }
        h64 += len;
        while (p + 8 <= bEnd) { uint64_t k1 = *(uint64_t*)p; k1 *= PRIME64_2; k1 = rotl64(k1, 31); k1 *= PRIME64_1; h64 ^= k1; h64 = rotl64(h64, 27) * PRIME64_1 + PRIME64_4; p += 8; }
        h64 ^= h64 >> 33; h64 *= PRIME64_2; h64 ^= h64 >> 29; h64 *= PRIME64_3; h64 ^= h64 >> 32;
        return h64;
    }
}

// ============================================================================
// PERISTYLE CORE LINK (base44.app Integration)
// ============================================================================
class CoreLinkClient {
public:
    struct Milestone {
        std::string title;
        std::string phase; // codex, architecture, terminal, visuals, release
        std::string status; // pending, in_progress, complete
    };

    explicit CoreLinkClient(const std::string& appId, const std::string& apiKey)
        : appId(appId), apiKey(apiKey) {}

    void postMilestone(const Milestone& m) {
        // Implementation for C++ REST call (simulated for standalone kernel)
        // In production, link against libcurl or httplib.h
        std::lock_guard<std::recursive_mutex> lock(consoleMutex);
        std::cout << colorCode(AnsiColor::AnsBLUE) << "[CORE-LINK] Syncing Milestone: " 
                  << m.title << " [" << m.phase << "]" << colorCode(AnsiColor::AnsRESET) << "\n";
        
        /* 
           POST /entities/Milestone HTTP/1.1
           Host: peristyle-core-link.base44.app
           api_key: f2ddd2b1d4aa43c9b6fccf47a1d5b74b
           Content-Type: application/json
           { "title": m.title, "phase": m.phase, "status": "complete" }
        */
    }

    void reportStatus(const std::string& msg, const std::string& mTitle, const std::string& phase) {
        // Matches ProjectStatus Schema
        std::lock_guard<std::recursive_mutex> lock(consoleMutex);
        std::cout << colorCode(AnsiColor::AnsBLUE) << "[CORE-LINK] Status Update: " << msg << colorCode(AnsiColor::AnsRESET) << "\n";
    }

private:
    std::string appId;
    std::string apiKey;
};

void printColored(const std::string& text, AnsiColor c) {
    {
        std::lock_guard<std::recursive_mutex> lock(consoleMutex);
        std::cout << colorCode(c) << text << colorCode(AnsiColor::AnsRESET);
    }
}

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

double clampDouble(double v, double lo, double hi) {
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
}

// Utility to trim whitespace from a string
std::string trim(const std::string& str) {
    size_t first = str.find_first_not_of(" \t\n\r");
    if (std::string::npos == first) {
        return str;
    }
    size_t last = str.find_last_not_of(" \t\n\r");
    return str.substr(first, (last - first + 1));
}

// File-safe timestamp for logs/reports
std::string filenameTimestamp() { return timestamp(true); }

// ============================================================================
// LOG MANAGER
// ============================================================================
class LogManager {
public:
    explicit LogManager(const std::string& path) : path_(path) {
        if (auto dir = fs::path(path_).parent_path(); !dir.empty()) {
            std::error_code ec;
            fs::create_directories(dir, ec);
        }
        stream_.open(path_, std::ios::app);
        if (stream_) {
            stream_ << "[" << timestamp(false) << "] Session started\n";
        }
    }

    void append(const std::string& message) {
        std::lock_guard<std::mutex> lock(mtx_);
        if (!stream_) return;
        stream_ << "[" << timestamp(false) << "] " << message << "\n";
    }
private:
    std::string path_;
    std::ofstream stream_;
    std::mutex mtx_;
};

// ============================================================================
// CONFIG, METRICS, STATE
// ============================================================================
struct Config {
    double baseSynchronization   = 0.85;
    double baseStability         = 0.80;
    double baseSustainability    = 0.95;
    double baseRuntimeIntegrity  = 0.90;

    double baseStressLoad        = 0.10;
    double baseEntropy           = 0.05;
    double baseErrorPropagation  = 0.05;

    int collapseThreshold        = 35;
    int recoveryThreshold        = 55;

    // Telemetry and Persistence
    int snapshotInterval         = 10;
    int maxSnapshotCache         = 100;
    int telemetryPort            = 8080;
    int telemetryHz              = 60;
    int shardCount               = 8;

    bool kidMode                 = false;
    bool expertMode              = true;
    double sustainBoostFactor    = 1.75;
    std::string logPath          = "logs/kkos_unified.log";
    std::string coreLinkAppId    = "6a2108a7b983285a8e8bc620";
    std::string coreLinkApiKey   = "f2ddd2b1d4aa43c9b6fccf47a1d5b74b";
    std::string reportsDir       = "reports";
};

// ============================================================================
// HYBRID TASK SCHEDULER (Raptor Lake Optimized)
// ============================================================================
enum class CoreTarget { PERFORMANCE, EFFICIENT };

class HybridTaskScheduler {
public:
    // Default for i5-13420H: 8 logical threads for P-cores, 4 for E-cores
    explicit HybridTaskScheduler(size_t p_core_threads = 8, size_t e_core_threads = 4) 
        : stop(false) {
        // Initialize Performance-core workers
        for(size_t i = 0; i < p_core_threads; ++i) {
            pcore_workers.emplace_back([this, i]() {
                while(true) {
                    std::function<void()> task;
                    {
                        std::unique_lock<std::mutex> lock(this->pcore_queue_mutex);
                        this->pcore_condition.wait(lock, [this]{ return this->stop || !this->pcore_tasks.empty(); });
                        if(this->stop.load() && this->pcore_tasks.empty()) return;
                        task = std::move(this->pcore_tasks.front());
                        this->pcore_tasks.pop();
                    }

                    #ifdef _WIN32
                    // Thread Affinity: Pin to P-Cores (Logical 0-7 on i5-13420H)
                    // Mask is a bitfield. 0xFF = first 8 logical processors.
                    DWORD_PTR p_mask = (DWORD_PTR)1 << (i % 8); 
                    SetThreadAffinityMask(GetCurrentThread(), p_mask);
                    
                    // Set higher priority for P-core tasks
                    // THREAD_PRIORITY_HIGHEST or THREAD_PRIORITY_ABOVE_NORMAL
                    SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_ABOVE_NORMAL);
                    // For more precise control, consider SetThreadAffinityMask or SetThreadGroupAffinity
                    // to explicitly bind to P-cores, but this is more complex and platform-specific.
                    #endif
                    task();
                }
            });
        }

        // Initialize Efficient-core workers
        for(size_t i = 0; i < e_core_threads; ++i) {
            ecore_workers.emplace_back([this, i]() {
                while(true) {
                    std::function<void()> task;
                    {
                        std::unique_lock<std::mutex> lock(this->ecore_queue_mutex);
                        this->ecore_condition.wait(lock, [this]{ return this->stop || !this->ecore_tasks.empty(); });
                        if(this->stop.load() && this->ecore_tasks.empty()) return;
                        task = std::move(this->ecore_tasks.front());
                        this->ecore_tasks.pop();
                    }

                    #ifdef _WIN32
                    // Thread Affinity: Pin to E-Cores (Logical 8-11 on i5-13420H)
                    DWORD_PTR e_mask = (DWORD_PTR)1 << (8 + (i % 4));
                    SetThreadAffinityMask(GetCurrentThread(), e_mask);

                    // Set lower priority for E-core tasks
                    // THREAD_PRIORITY_LOWEST or THREAD_PRIORITY_BELOW_NORMAL
                    SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_BELOW_NORMAL);
                    // For more precise control, consider SetThreadAffinityMask or SetThreadGroupAffinity
                    // to explicitly bind to E-cores.
                    #endif
                    task();
                }
            });
        }
    }

    ~HybridTaskScheduler() {
        {
            // Lock both mutexes to ensure all threads are notified safely
            std::unique_lock<std::mutex> p_lock(pcore_queue_mutex);
            std::unique_lock<std::mutex> e_lock(ecore_queue_mutex);
            stop = true;
        }
        pcore_condition.notify_all();
        ecore_condition.notify_all();
        for(std::thread &worker: pcore_workers) worker.join();
        for(std::thread &worker: ecore_workers) worker.join();
    }

    void execute(CoreTarget target, std::function<void()> task) {
        if (target == CoreTarget::PERFORMANCE) {
            {
                std::unique_lock<std::mutex> lock(pcore_queue_mutex);
                pcore_tasks.emplace(std::move(task));
            }
            pcore_condition.notify_one();
        } else { // CoreTarget::EFFICIENT
            {
                std::unique_lock<std::mutex> lock(ecore_queue_mutex);
                ecore_tasks.emplace(std::move(task));
            }
            ecore_condition.notify_one();
        }
    }

private:
    std::vector<std::thread> pcore_workers;
    std::queue<std::function<void()>> pcore_tasks;
    std::mutex pcore_queue_mutex;
    std::condition_variable pcore_condition;

    std::vector<std::thread> ecore_workers;
    std::queue<std::function<void()>> ecore_tasks;
    std::mutex ecore_queue_mutex;
    std::condition_variable ecore_condition;
    std::atomic<bool> stop;
};

// ============================================================================
// OPEN SOURCE DAW CORE (Digital Audio Workstation)
// ============================================================================
struct DAWTrack {
    std::string name;
    float volume = 0.8f;
    float peak = 0.0f; // Real-time peak level for visualizer
    bool muted = false;
    std::vector<uint8_t> sequence; // Pattern data inspired by FL Step Sequencer
    uint64_t integrity_hash = 0;
};

class DAWEngine {
public:
    DAWEngine() : rng(std::random_device{}()), running(false) {}
    ~DAWEngine() { running = false; }

    void initialize(HybridTaskScheduler& scheduler) {
        if (running) return;
        running = true;

        printColored("[DAW] Initializing Raptor-Lake Optimized Audio Engine...\n", AnsiColor::AnsMAGENTA);
        printColored("[DAW] Parsing FL Studio Pattern context from Bundle...\n", AnsiColor::AnsCYAN);
        addTrack("DRUMS_01");
        addTrack("BASS_SYNTH");
        addTrack("LEAD_V520");

        // Background task to simulate audio engine load on E-cores
        scheduler.execute(CoreTarget::EFFICIENT, [this]() {
            while(running) {
                std::this_thread::sleep_for(std::chrono::milliseconds(50));
                std::lock_guard<std::mutex> lock(tracksMutex);
                for(auto& t : tracks) {
                    // Simulate fluctuating peaks based on volume
                    std::uniform_real_distribution<float> dist(0.0f, t.volume);
                    t.peak = dist(rng);
                }
            }
        });
    }
    
    void addTrack(const std::string& name) {
        std::lock_guard<std::mutex> lock(tracksMutex);
        tracks.push_back({name});
        std::cout << "[DAW] Registered Track: " << name << " (Mapped to raudio buffer)\n";
    }

    void renderConsoleGrid() {
        std::lock_guard<std::mutex> lock(tracksMutex);
        printColored("--- DAW STEP SEQUENCER v1.0 ---\n", AnsiColor::AnsMAGENTA);
        for(auto& t : tracks) std::cout << "[TRACK: " << std::left << std::setw(10) << t.name << "] [||||||||]\n";
    }

    void renderVisualizer() {
        std::lock_guard<std::mutex> lock(tracksMutex);
        int startY = 100;
        for(size_t i = 0; i < tracks.size(); ++i) {
            ::DrawText(tracks[i].name.c_str(), 20, startY + (i * 40), 20, ::RAYWHITE);
            // Real-time Visualizer Bar using DrawRectangleRec
            ::Rectangle bar = { 150.0f, (float)startY + (i * 40), tracks[i].peak * 400.0f, 20.0f };
            ::Color barColor = (tracks[i].peak > 0.7f) ? ::RED : ::GREEN;
            ::DrawRectangleRec(bar, barColor);
            ::DrawRectangleLinesEx({ 150.0f, (float)startY + (i * 40), 400.0f, 20.0f }, 1, ::DARKGRAY);
        }
    }
private:
    std::vector<DAWTrack> tracks;
    std::atomic<bool> running;
    std::mt19937 rng;
    std::mutex tracksMutex;
};

struct CoherenceMetrics {
    double synchronization   = 0.7;
    double stability         = 0.7;
    double sustainability    = 0.7;
    double runtimeIntegrity  = 0.7;

    double stressLoad        = 0.2;
    double entropy           = 0.2;
    double errorPropagation  = 0.1;
    std::vector<float> shard_load; // Sharded metrics from v4.3
};

struct SystemState {
    bool inoculated          = false;
    bool collapsed           = false;
    bool sustaining          = false;

    CoherenceMetrics metrics;
    int coherenceScore       = 70;
    uint64_t stateHash       = 0;
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

void loadConfig(Config& cfg, const std::string& path) {
    if (!fs::exists(path)) {
        printColored("[SYSTEM] config.json missing. Using defaults.\n", AnsiColor::AnsYELLOW);
        return;
    }

    std::ifstream in(path);
    if (!in.is_open()) {
        printColored("[SYSTEM] Failed to open config.json. Using defaults.\n", AnsiColor::AnsRED);
        return;
    }

    printColored("[SYSTEM] Loading config.json...\n", AnsiColor::AnsCYAN);

    std::string line;
    while (std::getline(in, line)) {
        line = trim(line);

        if (line.empty() || line == "{" || line == "}") continue;

        auto pos = line.find(':');
        if (pos == std::string::npos) continue;

        std::string key = trim(line.substr(0, pos));
        std::string val = trim(line.substr(pos + 1));

        auto clean = [](std::string s) {
            const char* chars = " \t\r\n\",}]";
            s.erase(0, s.find_first_not_of(chars));
            size_t last = s.find_last_not_of(chars);
            if (last != std::string::npos) {
                s = s.substr(0, last + 1);
            }
            return s;
        };

        key = clean(key);
        val = clean(val);

        auto toDouble = [](const std::string& s, double def) {
            if (s.empty()) return def;
            try { return std::stod(s); } catch (...) { return def; }
        };
        auto toInt = [](const std::string& s, int def) {
            if (s.empty()) return def;
            try { return std::stoi(s); } catch (...) { return def; }
        };
        auto toBool = [](std::string s, bool def) {
            std::string low = s;
            std::transform(low.begin(), low.end(), low.begin(), [](unsigned char c){ return std::tolower(c); });
            return (low == "true" ? true : (low == "false" ? false : def));
        };

        if (key == "baseSynchronization")   cfg.baseSynchronization   = clampDouble(toDouble(val, cfg.baseSynchronization), 0.0, 1.0);
        else if (key == "baseStability")    cfg.baseStability         = clampDouble(toDouble(val, cfg.baseStability), 0.0, 1.0);
        else if (key == "baseSustainability") cfg.baseSustainability  = clampDouble(toDouble(val, cfg.baseSustainability), 0.0, 1.0);
        else if (key == "baseRuntimeIntegrity") cfg.baseRuntimeIntegrity = clampDouble(toDouble(val, cfg.baseRuntimeIntegrity), 0.0, 1.0);
        else if (key == "baseStressLoad")   cfg.baseStressLoad        = clampDouble(toDouble(val, cfg.baseStressLoad), 0.0, 1.0);
        else if (key == "baseEntropy")      cfg.baseEntropy           = clampDouble(toDouble(val, cfg.baseEntropy), 0.0, 1.0);
        else if (key == "baseErrorPropagation") cfg.baseErrorPropagation = clampDouble(toDouble(val, cfg.baseErrorPropagation), 0.0, 1.0);
        else if (key == "collapseThreshold") cfg.collapseThreshold    = toInt(val, cfg.collapseThreshold);
        else if (key == "recoveryThreshold") cfg.recoveryThreshold    = toInt(val, cfg.recoveryThreshold);
        else if (key == "kidMode")          cfg.kidMode               = toBool(val, cfg.kidMode);
        else if (key == "expertMode")       cfg.expertMode            = toBool(val, cfg.expertMode);
        else if (key == "sustainBoostFactor") cfg.sustainBoostFactor  = clampDouble(toDouble(val, cfg.sustainBoostFactor), 0.1, 5.0);
        else if (key == "snapshotInterval")   cfg.snapshotInterval    = toInt(val, cfg.snapshotInterval);
        else if (key == "maxSnapshotCache")   cfg.maxSnapshotCache    = toInt(val, cfg.maxSnapshotCache);
        else if (key == "telemetryPort")      cfg.telemetryPort       = toInt(val, cfg.telemetryPort);
        else if (key == "telemetryHz")        cfg.telemetryHz         = toInt(val, cfg.telemetryHz);
        else if (key == "shardCount")         cfg.shardCount          = toInt(val, cfg.shardCount);
        else if (key == "logPath")            cfg.logPath             = val;
        else if (key == "reportsDir")         cfg.reportsDir          = val;
        else if (key == "coreLinkAppId")      cfg.coreLinkAppId       = val;
        else if (key == "coreLinkApiKey")     cfg.coreLinkApiKey      = val;
    }

    printColored("[SYSTEM] Config mapped successfully.\n", AnsiColor::AnsGREEN);
}

// ============================================================================
// COHERENCE ENGINE
// ============================================================================
class CoherenceEngine {
public:
    explicit CoherenceEngine(const Config& cfg)
        : cfg(cfg),
          rng(std::random_device{}()),
          noise(-0.02, 0.02) {}

    void initialize(SystemState& state) {
        state.inoculated = true;
        state.collapsed  = false;
        state.sustaining = false;

        state.metrics.synchronization  = cfg.baseSynchronization;
        state.metrics.stability        = cfg.baseStability;
        state.metrics.sustainability   = cfg.baseSustainability;
        state.metrics.runtimeIntegrity = cfg.baseRuntimeIntegrity;
        state.metrics.stressLoad       = cfg.baseStressLoad;
        state.metrics.entropy          = cfg.baseEntropy;
        state.metrics.errorPropagation = cfg.baseErrorPropagation;
        state.metrics.shard_load.assign(cfg.shardCount, 0.1f);

        state.coherenceScore = compute(state.metrics);
    }

    void applyStress(SystemState& state, double magnitude) {
        magnitude = clampDouble(magnitude, 0.0, 1.0);

        state.metrics.stressLoad       = clampDouble(state.metrics.stressLoad + magnitude * 0.28, 0.0, 1.0);
        state.metrics.entropy          = clampDouble(state.metrics.entropy + magnitude * 0.22, 0.0, 1.0);
        state.metrics.errorPropagation = clampDouble(state.metrics.errorPropagation + magnitude * 0.18, 0.0, 1.0);

        state.metrics.synchronization  = clampDouble(state.metrics.synchronization - magnitude * 0.15, 0.0, 1.0);
        state.metrics.stability        = clampDouble(state.metrics.stability - magnitude * 0.20, 0.0, 1.0);
        state.metrics.sustainability   = clampDouble(state.metrics.sustainability - magnitude * 0.12, 0.0, 1.0);
        state.metrics.runtimeIntegrity = clampDouble(state.metrics.runtimeIntegrity - magnitude * 0.15, 0.0, 1.0);

        for(auto& s : state.metrics.shard_load) {
            s = clampDouble(s + (magnitude * 0.1), 0.0, 1.0);
        }

        state.coherenceScore = compute(state.metrics);
        if (state.coherenceScore < cfg.collapseThreshold) {
            state.collapsed = true;
        }
    }

    void sustain(SystemState& state, double effort) {
        effort = clampDouble(effort * cfg.sustainBoostFactor, 0.0, 1.0);
        state.sustaining = true;

        state.metrics.stressLoad       = clampDouble(state.metrics.stressLoad - effort * 0.30, 0.0, 1.0);
        state.metrics.entropy          = clampDouble(state.metrics.entropy - effort * 0.25, 0.0, 1.0);
        state.metrics.errorPropagation = clampDouble(state.metrics.errorPropagation - effort * 0.20, 0.0, 1.0);

        state.metrics.synchronization  = clampDouble(state.metrics.synchronization + effort * 0.20, 0.0, 1.0);
        state.metrics.stability        = clampDouble(state.metrics.stability + effort * 0.25, 0.0, 1.0);
        state.metrics.sustainability   = clampDouble(state.metrics.sustainability + effort * 0.35, 0.0, 1.0);
        state.metrics.runtimeIntegrity = clampDouble(state.metrics.runtimeIntegrity + effort * 0.20, 0.0, 1.0);

        state.coherenceScore = compute(state.metrics);
        if (state.coherenceScore >= cfg.recoveryThreshold) {
            state.collapsed = false;
        }
    }

    void reset(SystemState& state) {
        state = SystemState{};
    }

    int compute(const CoherenceMetrics& m) {
        double positive = m.synchronization + m.stability + m.sustainability + m.runtimeIntegrity;
        double negative = m.stressLoad + m.entropy + m.errorPropagation;
        
        // v4.5 Enhanced Non-Linear Coherence Model
        // Weighting sustainability and integrity higher for high-performance mobile nodes
        double weighted_pos = (m.synchronization * 1.1) + m.stability + (m.sustainability * 1.2) + (m.runtimeIntegrity * 1.15);
        double weighted_neg = (m.stressLoad * 0.9) + m.entropy + (m.errorPropagation * 1.1);

        double base = (weighted_pos - weighted_neg) / 1.1;
        base += noise(rng);

        base = clampDouble(base, -2.0, 2.0);
        double normalized = (base + 2.0) / 4.0;
        
        int score = static_cast<int>(std::round(normalized * 100.0));
        return std::clamp(score, 0, 100);
    }

private:
    const Config& cfg;
    std::mt19937 rng;
    std::uniform_real_distribution<double> noise;
};

// ============================================================================
// RUNTIME CONTEXT
// ============================================================================
struct RuntimeContext {
    SystemState state;
    Config config;
    std::unique_ptr<LogManager> logger;
    std::unique_ptr<CoherenceEngine> engine;
    std::unique_ptr<HybridTaskScheduler> scheduler;
    std::unique_ptr<DAWEngine> daw;
    std::unique_ptr<CoreLinkClient> link;
    std::atomic<bool> running = true;
    std::string logFilePath;
    std::vector<TelemetrySample> telemetryHistory;
    std::vector<CodexEntry> codexDatabase;
    std::recursive_mutex stateMutex;
};
// ============================================================================
// FOUR-MOTHER PIPELINE
// ============================================================================
class FourMotherPipeline {
public:
    using CommandFunc = std::function<void(RuntimeContext&, const std::string&)>;

    explicit FourMotherPipeline(RuntimeContext& ctx) : ctx(ctx) {}

    void registerCommand(const std::string& name, CommandFunc fn, const std::string& description) {
        commands[name] = fn;
        helpText[name] = description;
    }

    void processLine(const std::string& line) {
        std::lock_guard lock(ctx.stateMutex);
        std::string cmd, args;

        // GATE
        if (!gate(line, cmd, args)) return;

        // THRESHOLD
        if (!threshold(cmd)) {
            ctx.logger->append("[THRESHOLD] Rejection - Unknown token: " + cmd);
            if (ctx.config.kidMode) {
                printColored("Oops! I don't know that command. Try 'help' to see options.\n", AnsiColor::AnsYELLOW);
            } else {
                printColored("[ERR-STATE: CHOFE] Unknown directive. Call 'help' for schema directories.\n", AnsiColor::AnsRED);
            }
            ctx.engine->applyStress(ctx.state, 0.06);
            return;
        }

        // KILN
        kiln(cmd, args);

        // CRYPT
        crypt(cmd, args);
    }

    void printHelp() {
        if (ctx.config.kidMode) {
            printColored("\n--- SYSTEM CONTROLS ---\n", AnsiColor::AnsCYAN);
            std::lock_guard<std::recursive_mutex> lock(consoleMutex);
            for (const auto& kv : helpText) {
                std::cout << " * " << std::left << std::setw(14) << kv.first << " : " << kv.second << "\n";
            }
        } else {
            printColored("\n=== PERISTYLE CORE STRUCTURAL COMPASS DIRECTORY ===\n", AnsiColor::AnsCYAN);
            std::lock_guard<std::recursive_mutex> lock(consoleMutex);
            for (const auto& kv : helpText) {
                std::cout << "  " << std::left << std::setw(12) << kv.first << " - " << kv.second << "\n";
            }
        }
    }

private:
    RuntimeContext& ctx;
    std::unordered_map<std::string, CommandFunc> commands;
    std::unordered_map<std::string, std::string> helpText;

    bool gate(const std::string& line, std::string& cmdOut, std::string& argsOut) {
        std::string trimmed = line;
        trimmed.erase(trimmed.begin(), std::find_if(trimmed.begin(), trimmed.end(), [](unsigned char ch) {
            return !std::isspace(ch);
        }));
        trimmed.erase(std::find_if(trimmed.rbegin(), trimmed.rend(), [](unsigned char ch) {
            return !std::isspace(ch);
        }).base(), trimmed.end());

        if (trimmed.empty()) return false;

        std::stringstream ss(trimmed);
        ss >> cmdOut;
        std::getline(ss, argsOut);
        if (!argsOut.empty() && argsOut.front() == ' ') argsOut.erase(0, 1);
        return true;
    }

    bool threshold(const std::string& cmd) {
        return commands.find(cmd) != commands.end();
    }

    void kiln(const std::string& cmd, const std::string& args) {
        commands[cmd](ctx, args);

        if (ctx.state.inoculated) {
            TelemetrySample sample;
            sample.timestamp = timestamp(false);
            sample.coherenceScore = ctx.state.coherenceScore;
            sample.metrics = ctx.state.metrics;
            ctx.telemetryHistory.push_back(sample);
            
            // FIXED: Hash vector data instead of vector descriptor
            uint64_t baseHash = xxh::xxhash64(&ctx.state.metrics.synchronization, 7 * sizeof(double));
            uint64_t shardHash = xxh::xxhash64(ctx.state.metrics.shard_load.data(), ctx.state.metrics.shard_load.size() * sizeof(float));
            ctx.state.stateHash = baseHash ^ shardHash;
        }

        // Automatically sync milestones to Base44 Peristyle Core Link
        if (cmd == "inoculate") {
            ctx.link->postMilestone({"Kernel Initialization", "architecture", "complete"});
        } else if (cmd == "daw-init") {
            ctx.link->postMilestone({"Audio Engine Online", "terminal", "complete"});
            ctx.link->reportStatus("DAW Engine synchronized with Hybrid Scheduler", "Audio Engine Online", "terminal");
        }
    }

    void crypt(const std::string& cmd, const std::string& args) {
        std::string logMsg = "Executed token: " + cmd;
        if (!args.empty()) logMsg += " with payload: [" + args + "]";
        ctx.logger->append("[CRYPT] " + logMsg);
    }

    void writeLog(const std::string& stage, const std::string& entry) {
        if (ctx.logFilePath.empty()) return;
        std::ofstream logFile(ctx.logFilePath, std::ios::app);
        if (logFile.is_open()) {
            logFile << "[" << timestamp(false) << "] [" << stage << "] " << entry << "\n";
        }
    }
};

// ============================================================================
// RENDER HELPERS
// ============================================================================
void renderStatus(const RuntimeContext& ctx) {
    std::lock_guard<std::recursive_mutex> lock(consoleMutex);
    if (ctx.config.kidMode) {
        printColored("\n--- SYSTEM HEALTH BALANCE INTERFACE ---\n", AnsiColor::AnsCYAN);
        std::cout << "Engine Pulse:   ";
        if (!ctx.state.inoculated) printColored("Dormant/Resting\n", AnsiColor::AnsYELLOW);
        else if (ctx.state.collapsed) printColored("Grid Overload! Needs support.\n", AnsiColor::AnsRED);
        else if (ctx.state.sustaining) printColored("Optimizing structures smoothly.\n", AnsiColor::AnsGREEN);
        else printColored("Balanced and running happily.\n", AnsiColor::AnsGREEN);

        std::cout << "Coherence Bar:  ";
        AnsiColor color = AnsiColor::AnsGREEN;
        if (ctx.state.coherenceScore < 35) color = AnsiColor::AnsRED;
        else if (ctx.state.coherenceScore < 65) color = AnsiColor::AnsYELLOW;

        std::string bar = "[";
        int ticks = ctx.state.coherenceScore / 5;
        for (int i = 0; i < 20; ++i) bar += (i < ticks) ? "■" : " ";
        bar += "] " + std::to_string(ctx.state.coherenceScore) + "%\n";
        printColored(bar, color);
        printColored("---------------------------------------\n", AnsiColor::AnsCYAN);
        return;
    }

    printColored("\n================ CORE INTERFACE TELEMETRY DUMP ================\n", AnsiColor::AnsCYAN);
    std::cout << "STRUCTURAL STATE INVARIANT : ";
    if (!ctx.state.inoculated) printColored("PAGE-0 (DORMANT_CORE_STATE)\n", AnsiColor::AnsYELLOW);
    else if (ctx.state.collapsed) printColored("STATE_HAZARD: CHOFE (CRITICAL_DECOHERENCE)\n", AnsiColor::AnsRED);
    else if (ctx.state.sustaining) printColored("PAGE-1 (OPTIMIZATION_SUSTAIN_VECTOR)\n", AnsiColor::AnsGREEN);
    else printColored("PAGE-1 (STEADY_STATE_RUNNING)\n", AnsiColor::AnsGREEN);

    std::cout << "INTEGRATION BALANCE MARGIN : ";
    AnsiColor scoreColor = AnsiColor::AnsGREEN;
    if (ctx.state.coherenceScore < 35) scoreColor = AnsiColor::AnsRED;
    else if (ctx.state.coherenceScore < 60) scoreColor = AnsiColor::AnsYELLOW;

    std::string bar = "[";
    int ticks = ctx.state.coherenceScore / 5;
    for (int i = 0; i < 20; ++i) bar += (i < ticks) ? "■" : " ";
    bar += "] VECTOR_METRIC: " + std::to_string(ctx.state.coherenceScore) + "%\n";
    printColored(bar, scoreColor);

    std::cout << std::fixed << std::setprecision(4);
    std::cout << "  ⚡ SYSTEM_SYNCHRONIZATION [Sny] : " << ctx.state.metrics.synchronization << "\n"
              << "  ⚡ ENVIRONMENT_STABILITY  [Stb] : " << ctx.state.metrics.stability << "\n"
              << "  ⚡ RESOURCE_SUSTAINABILITY[Sus] : " << ctx.state.metrics.sustainability << "\n"
              << "  ⚡ CORE_RUNTIME_INTEGRITY [Int] : " << ctx.state.metrics.runtimeIntegrity << "\n"
              << "  🔥 INTRODUCED_STRESS_LOAD [Str] : " << ctx.state.metrics.stressLoad << "\n"
              << "  🔥 CALCULATION_ENTROPY    [Ent] : " << ctx.state.metrics.entropy << "\n"
              << "  🔥 RUNTIME_ERR_PROPAGATION[Erp] : " << ctx.state.metrics.errorPropagation << "\n";
    printColored("===============================================================\n", AnsiColor::AnsCYAN);
}

void initCodex(std::vector<CodexEntry>& db) {
    db.push_back({"gate", "Mama Legba validation intercept tracking routines.", "Codex Manual Sec III.A"});
    db.push_back({"threshold", "Ayizan verification boundaries parsing inbound data structures.", "Codex Manual Sec III.B"});
    db.push_back({"kiln", "Transformation space tracking calculation mutations.", "Codex Manual Sec III.C"});
    db.push_back({"crypt", "Ledger indexing locking records onto non-volatile log directories.", "Codex Manual Sec III.D"});
    db.push_back({"chofe", "System failure state caused by execution inversion exceptions.", "Codex Manual Sec VIII.E"});
    db.push_back({"solarpunk", "Regenerative technical alignment engineering anti-black-box execution layers.", "Governance Declarations Sec I.A"});
}

// ============================================================================
// MAIN
// ============================================================================
int main() {
    RuntimeContext ctx;
    loadConfig(ctx.config, "config.json");
    ctx.engine = std::make_unique<CoherenceEngine>(ctx.config);
    initCodex(ctx.codexDatabase);

    // Initialize core systems to avoid null pointer dereferences and enable thread management
    ctx.scheduler = std::make_unique<HybridTaskScheduler>();
    ctx.daw = std::make_unique<DAWEngine>();

    // Initialize Peristyle Core Link Client with provided API credentials
    ctx.link = std::make_unique<CoreLinkClient>(ctx.config.coreLinkAppId, ctx.config.coreLinkApiKey);

    ctx.logger = std::make_unique<LogManager>(ctx.config.logPath);

    ctx.logFilePath = ctx.config.logPath;
    try {
        fs::create_directories(ctx.config.reportsDir);
    } catch (...) {
        printColored("[SYSTEM] Failed to ensure reports directory exists.\n", AnsiColor::AnsRED);
    }

    FourMotherPipeline pipeline(ctx);

    pipeline.registerCommand("daw-init", [](RuntimeContext& c, const std::string&) {
        c.daw->initialize(*c.scheduler);
        c.daw->addTrack("KICK");
        c.daw->addTrack("SNARE");
        c.daw->renderConsoleGrid();
    }, "Initialize Open Source DAW and load FL Studio patterns.");

    pipeline.registerCommand("inoculate", [](RuntimeContext& c, const std::string&) {
        c.engine->initialize(c.state);
        printColored("[SYSTEM] Peristyle structure initialized. Baseline constraints committed.\n", AnsiColor::AnsGREEN);
    }, "Boot structural simulation state parameters mapping into memory context.");

    pipeline.registerCommand("collapse", [](RuntimeContext& c, const std::string& args) {
        double intensity = 0.50;
        if (!args.empty()) { try { intensity = std::stod(args); } catch (...) {} }
        c.engine->applyStress(c.state, intensity);
        printColored("[SYSTEM] Inbound structural calculation overload requested.\n", AnsiColor::AnsRED);
    }, "Simulate dynamic computational load vector stress propagation.");

    pipeline.registerCommand("sustain", [](RuntimeContext& c, const std::string& args) {
        double strength = 0.50;
        if (!args.empty()) { try { strength = std::stod(args); } catch (...) {} }
        c.engine->sustain(c.state, strength);
        printColored("[SYSTEM] Dispatching solarpunk optimization matrices.\n", AnsiColor::AnsGREEN);
    }, "Apply regenerative optimization models.");

    pipeline.registerCommand("status", [](RuntimeContext& c, const std::string& args) {
        if (args == "--json") {
            {
                std::lock_guard lock(consoleMutex);
                std::cout << "{\n"
                          << "  \"coherenceScore\": " << c.state.coherenceScore << ",\n"
                          << "  \"inoculated\": " << (c.state.inoculated ? "true" : "false") << ",\n"
                          << "  \"collapsed\": " << (c.state.collapsed ? "true" : "false") << "\n"
                          << "}\n";
            }
        } else {
            renderStatus(c);
        }
    }, "Dump global status vectors and Coherence Meter.");

    pipeline.registerCommand("coherence", [](RuntimeContext& c, const std::string&) {
        std::cout << "Centralized Coherence Factor Index: ";
        AnsiColor color = AnsiColor::AnsGREEN;
        if (c.state.coherenceScore < 35) color = AnsiColor::AnsRED;
        else if (c.state.coherenceScore < 65) color = AnsiColor::AnsYELLOW;
        printColored(std::to_string(c.state.coherenceScore) + "%\n", color);
    }, "Quick view of centralized system stability percentage.");

    pipeline.registerCommand("reset", [](RuntimeContext& c, const std::string&) {
        c.engine->reset(c.state);
        printColored("[SYSTEM] Runtime matrices cleared. Returned to PAGE-0.\n", AnsiColor::AnsYELLOW);
    }, "Return system to dormant baseline.");

    pipeline.registerCommand("toggle-ux", [](RuntimeContext& c, const std::string&) {
        c.config.kidMode = !c.config.kidMode;
        c.config.expertMode = !c.config.kidMode;
        if (c.config.kidMode) {
            printColored("[INTERFACE] KID MODE enabled. Friendly abstraction active.\n", AnsiColor::AnsYELLOW);
        } else {
            printColored("[INTERFACE] EXPERT MODE enabled. Raw telemetry active.\n", AnsiColor::AnsCYAN);
        }
    }, "Swap between Kid and Expert UX modes.");

    pipeline.registerCommand("codex", [](RuntimeContext& c, const std::string& args) {
        std::stringstream ss(args);
        std::string sub, query;
        ss >> sub;
        std::getline(ss, query);
        if (!query.empty() && query.front() == ' ') query.erase(0, 1);
        std::string qLower = query;
        std::transform(qLower.begin(), qLower.end(), qLower.begin(), ::tolower);

        if (sub != "search" || qLower.empty()) {
            printColored("Usage: codex search <term>\n", AnsiColor::AnsYELLOW);
            return;
        }

        bool found = false;
        printColored("\n--- SYSTEM REGISTER INTERROGATION: KURFEW KULT CODEX ---\n", AnsiColor::AnsMAGENTA);
        for (const auto& e : c.codexDatabase) {
            std::string keyLower = e.key;
            std::string contentLower = e.content;
            std::transform(keyLower.begin(), keyLower.end(), keyLower.begin(), ::tolower);
            std::transform(contentLower.begin(), contentLower.end(), contentLower.begin(), ::tolower);
            if (keyLower.find(qLower) != std::string::npos || contentLower.find(qLower) != std::string::npos) {
                printColored("[" + e.key + "]\n", AnsiColor::AnsCYAN);
                std::cout << "  Abstract Mapping: " << e.content << "\n";
                printColored("  Verification:     " + e.citation + "\n\n", AnsiColor::AnsYELLOW);
                found = true;
            }
        }
        if (!found) {
            printColored("No documented operational references found for query.\n", AnsiColor::AnsRED);
        }
    }, "Query Kurfew Kult Codex v17.0 entries.");

    pipeline.registerCommand("telemetry", [](RuntimeContext& c, const std::string& args) {
        if (args != "export --json") {
            printColored("Usage: telemetry export --json\n", AnsiColor::AnsYELLOW);
            return;
        }

        std::error_code ec;
        fs::create_directories(c.config.reportsDir, ec);
        std::string path = c.config.reportsDir + "/telemetry_" + filenameTimestamp() + ".json";
        std::ofstream out(path);
        if (!out.is_open()) {
            printColored("[FILE] Could not open telemetry export path.\n", AnsiColor::AnsRED);
            return;
        }

        out << "{\n  \"telemetryHistory\": [\n";
        for (size_t i = 0; i < c.telemetryHistory.size(); ++i) {
            const auto& s = c.telemetryHistory[i];
            out << "    {\n"
                << "      \"timestamp\": \"" << s.timestamp << "\",\n"
                << "      \"coherenceScore\": " << s.coherenceScore << ",\n"
                << "      \"metrics\": {\n"
                << "        \"synchronization\": " << s.metrics.synchronization << ",\n"
                << "        \"stability\": " << s.metrics.stability << ",\n"
                << "        \"sustainability\": " << s.metrics.sustainability << ",\n"
                << "        \"runtimeIntegrity\": " << s.metrics.runtimeIntegrity << ",\n"
                << "        \"stressLoad\": " << s.metrics.stressLoad << ",\n"
                << "        \"entropy\": " << s.metrics.entropy << ",\n"
                << "        \"errorPropagation\": " << s.metrics.errorPropagation << "\n"
                << "      }\n"
                << "    }" << (i + 1 < c.telemetryHistory.size() ? "," : "") << "\n";
        }
        out << "  ]\n}\n";
        printColored("[SYSTEM] Telemetry export complete: " + path + "\n", AnsiColor::AnsGREEN);
    }, "Export telemetry history as JSON.");

    pipeline.registerCommand("help", [&pipeline](RuntimeContext&, const std::string&) {
        pipeline.printHelp();
    }, "List available commands and descriptions.");

    pipeline.registerCommand("exit", [](RuntimeContext& c, const std::string&) {
        printColored("Decommissioning active Peristyle subgrids. Exiting context safely.\n", AnsiColor::AnsCYAN);
        c.running = false;
    }, "Terminate the active orchestration session safely.");

    printColored("===============================================================\n", AnsiColor::AnsCYAN);
    {
        std::stringstream ss;
        ss << " KKOS v" << KKOS_VERSION_STR << " UNIFIED // DAW ENGINE // RAPTOR LAKE OPTIMIZED      \n";
        printColored(ss.str(), AnsiColor::AnsCYAN);
    }
    printColored("===============================================================\n", AnsiColor::AnsCYAN);
    std::cout << "Hardware Node : LOVEMYDOUBLECUP (Acer Nitro ANV15-52)\n";
    std::cout << "Processor     : 13th Gen Intel(R) Core(TM) i5-13420H\n";
    std::cout << "Architecture  : Hybrid (4P + 4E) // 12 Logical Processors\n";
    // Ensure runtime environment directories are ready
    std::error_code dir_ec;
    fs::create_directories(fs::path(ctx.config.logPath).parent_path(), dir_ec);

    std::cout << "Log routing: " << ctx.logFilePath << "\n";
    std::cout << "Type 'help' to review structural orchestration controls.\n";

    // Raylib Visualizer Initialization
    InitWindow(800, 450, "KKOS v5.2.0 - DAW Visualizer");
    SetTargetFPS(60);

    // Run shell on a separate Performance thread to avoid blocking the GUI
    ctx.scheduler->execute(CoreTarget::PERFORMANCE, [&]() {
        std::string line;
        std::cout << "\n[kkos_v" << KKOS_VERSION_STR << "_unified]> " << std::flush;
        while (ctx.running) {
            #ifdef _WIN32
            if (_kbhit()) {
                int ch = _getch();
                if (ch == 13 || ch == 10) { // Enter key
                    std::cout << std::endl;
                    if (!line.empty()) {
                        pipeline.processLine(line);
                        line.clear();
                    }
                    if (ctx.running) std::cout << "[kkos_v" << KKOS_VERSION_STR << "_unified]> " << std::flush;
                } else if (ch == 8) { // Backspace
                    if (!line.empty()) {
                        line.pop_back();
                        std::cout << "\b \b" << std::flush;
                    }
                } else if (ch >= 32 && ch <= 126) { // Printable characters
                    line += static_cast<char>(ch);
                    std::cout << static_cast<char>(ch) << std::flush;
                }
            } else {
                std::this_thread::sleep_for(std::chrono::milliseconds(20));
            }
            #else
            if (!std::getline(std::cin, line)) break;
            pipeline.processLine(line);
            if (ctx.running) std::cout << "[kkos_v" << KKOS_VERSION_STR << "_unified]> " << std::flush;
            #endif
        }
    });

    // Main Render Loop
    while (!WindowShouldClose() && ctx.running) {
        BeginDrawing();
        ClearBackground({ 20, 20, 20, 255 });
        std::lock_guard lock(ctx.stateMutex);
        ::DrawText(TextFormat("KKOS v%s - PERFORMANCE NODE: LOVEMYDOUBLECUP", KKOS_VERSION_STR), 20, 20, 20, ::SKYBLUE);
        ::DrawText("Hybrid Scheduler: Threads distributed across P/E Cores", 20, 50, 10, ::GRAY);
        ::DrawText(TextFormat("Integrity Hash: %llu", ctx.state.stateHash), 20, 70, 10, ::DARKGREEN);
        
        ctx.daw->renderVisualizer();
        
        EndDrawing();
    }

    ::CloseWindow();

    return 0;
}
