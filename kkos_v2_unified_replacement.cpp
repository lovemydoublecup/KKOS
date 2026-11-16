// ============================================================================
// KKOS v2.1 // PERISTYLE KERNEL v3.4 // COHERENCE-DRIVEN SIMULATION CORE
// Monolithic, zero-dependency C++17 single-source module
// ============================================================================

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
#include <memory>
#include <cctype>

namespace fs = std::filesystem;

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

    bool kidMode                 = false;
    bool expertMode              = true;
    double sustainBoostFactor    = 1.75;
};

struct CoherenceMetrics {
    double synchronization   = 0.7;
    double stability         = 0.7;
    double sustainability    = 0.7;
    double runtimeIntegrity  = 0.7;

    double stressLoad        = 0.2;
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

// ============================================================================
// ANSI / TIME / UTILS
// ============================================================================
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

void loadConfig(Config& cfg, const std::string& path) {
    std::ifstream in(path);
    if (!in.is_open()) {
        printColored("[SYSTEM] No config.json found. Using canonical hardcoded baselines.\n", AnsiColor::YELLOW);
        return;
    }

    printColored("[SYSTEM] Loading config.json...\n", AnsiColor::CYAN);

    std::string line;
    while (std::getline(in, line)) {
        // Trim only leading/trailing whitespace to preserve internal string spaces
        line.erase(0, line.find_first_not_of(" \t\r\n"));
        auto last = line.find_last_not_of(" \t\r\n");
        if (last != std::string::npos) line.erase(last + 1);

        if (line.empty() || line == "{" || line == "}" || line == "},") continue;

        auto pos = line.find(':');
        if (pos == std::string::npos) continue;

        std::string key = line.substr(0, pos);
        std::string val = line.substr(pos + 1);

        if (!key.empty() && key.front() == '"') key.erase(0, 1);
        if (!key.empty() && key.back() == '"') key.pop_back();
        if (!val.empty() && val.back() == ',') val.pop_back();

        auto toDouble = [](const std::string& s, double def) {
            try { return std::stod(s); } catch (...) { return def; }
        };
        auto toInt = [](const std::string& s, int def) {
            try { return std::stoi(s); } catch (...) { return def; }
        };
        auto toBool = [](std::string s, bool def) {
            std::transform(s.begin(), s.end(), s.begin(), ::tolower);
            if (s == "true") return true;
            if (s == "false") return false;
            return def;
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
    }

    printColored("[SYSTEM] Config mapped successfully.\n", AnsiColor::GREEN);
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

        double base = positive - negative;
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
    std::unique_ptr<CoherenceEngine> engine;
    bool running = true;
    std::string logFilePath;
    std::vector<TelemetrySample> telemetryHistory;
    std::vector<CodexEntry> codexDatabase;
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
        std::string cmd, args;

        // GATE
        if (!gate(line, cmd, args)) return;

        // THRESHOLD
        if (!threshold(cmd)) {
            writeLog("THRESHOLD", "Rejection - Unknown token: " + cmd);
            if (ctx.config.kidMode) {
                printColored("Oops! I don't know that command. Try 'help' to see options.\n", AnsiColor::YELLOW);
            } else {
                printColored("[ERR-STATE: CHOFE] Unknown directive. Call 'help' for schema directories.\n", AnsiColor::RED);
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
            printColored("\n--- SYSTEM CONTROLS ---\n", AnsiColor::CYAN);
            for (const auto& kv : helpText) {
                std::cout << " * " << std::left << std::setw(14) << kv.first << " : " << kv.second << "\n";
            }
        } else {
            printColored("\n=== PERISTYLE CORE STRUCTURAL COMPASS DIRECTORY ===\n", AnsiColor::CYAN);
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
        }
    }

    void crypt(const std::string& cmd, const std::string& args) {
        std::string logMsg = "Executed token: " + cmd;
        if (!args.empty()) logMsg += " with payload: [" + args + "]";
        writeLog("CRYPT", logMsg);
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
    if (ctx.config.kidMode) {
        printColored("\n--- SYSTEM HEALTH BALANCE INTERFACE ---\n", AnsiColor::CYAN);
        std::cout << "Engine Pulse:   ";
        if (!ctx.state.inoculated) printColored("Dormant/Resting\n", AnsiColor::YELLOW);
        else if (ctx.state.collapsed) printColored("Grid Overload! Needs support.\n", AnsiColor::RED);
        else if (ctx.state.sustaining) printColored("Optimizing structures smoothly.\n", AnsiColor::GREEN);
        else printColored("Balanced and running happily.\n", AnsiColor::GREEN);

        std::cout << "Coherence Bar:  ";
        AnsiColor color = AnsiColor::GREEN;
        if (ctx.state.coherenceScore < 35) color = AnsiColor::RED;
        else if (ctx.state.coherenceScore < 65) color = AnsiColor::YELLOW;

        std::string bar = "[";
        int ticks = ctx.state.coherenceScore / 5;
        for (int i = 0; i < 20; ++i) bar += (i < ticks) ? "■" : " ";
        bar += "] " + std::to_string(ctx.state.coherenceScore) + "%\n";
        printColored(bar, color);
        printColored("---------------------------------------\n", AnsiColor::CYAN);
        return;
    }

    printColored("\n================ CORE INTERFACE TELEMETRY DUMP ================\n", AnsiColor::CYAN);
    std::cout << "STRUCTURAL STATE INVARIANT : ";
    if (!ctx.state.inoculated) printColored("PAGE-0 (DORMANT_CORE_STATE)\n", AnsiColor::YELLOW);
    else if (ctx.state.collapsed) printColored("STATE_HAZARD: CHOFE (CRITICAL_DECOHERENCE)\n", AnsiColor::RED);
    else if (ctx.state.sustaining) printColored("PAGE-1 (OPTIMIZATION_SUSTAIN_VECTOR)\n", AnsiColor::GREEN);
    else printColored("PAGE-1 (STEADY_STATE_RUNNING)\n", AnsiColor::GREEN);

    std::cout << "INTEGRATION BALANCE MARGIN : ";
    AnsiColor scoreColor = AnsiColor::GREEN;
    if (ctx.state.coherenceScore < 35) scoreColor = AnsiColor::RED;
    else if (ctx.state.coherenceScore < 60) scoreColor = AnsiColor::YELLOW;

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
    printColored("===============================================================\n", AnsiColor::CYAN);
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

    try {
        fs::create_directories("logs");
        ctx.logFilePath = "logs/coherence_" + timestamp(true).substr(0, 8) + ".log";
    } catch (...) {
        ctx.logFilePath = "kkos_runtime.log";
    }

    FourMotherPipeline pipeline(ctx);

    pipeline.registerCommand("inoculate", [](RuntimeContext& c, const std::string&) {
        c.engine->initialize(c.state);
        printColored("[SYSTEM] Peristyle structure initialized. Baseline constraints committed.\n", AnsiColor::GREEN);
    }, "Boot structural simulation state parameters mapping into memory context.");

    pipeline.registerCommand("collapse", [](RuntimeContext& c, const std::string& args) {
        double intensity = 0.50;
        if (!args.empty()) { try { intensity = std::stod(args); } catch (...) {} }
        c.engine->applyStress(c.state, intensity);
        printColored("[SYSTEM] Inbound structural calculation overload requested.\n", AnsiColor::RED);
    }, "Simulate dynamic computational load vector stress propagation.");

    pipeline.registerCommand("sustain", [](RuntimeContext& c, const std::string& args) {
        double strength = 0.50;
        if (!args.empty()) { try { strength = std::stod(args); } catch (...) {} }
        c.engine->sustain(c.state, strength);
        printColored("[SYSTEM] Dispatching solarpunk optimization matrices.\n", AnsiColor::GREEN);
    }, "Apply regenerative optimization models.");

    pipeline.registerCommand("status", [](RuntimeContext& c, const std::string&) {
        renderStatus(c);
    }, "Dump global status vectors and Coherence Meter.");

    pipeline.registerCommand("coherence", [](RuntimeContext& c, const std::string&) {
        std::cout << "Centralized Coherence Factor Index: ";
        AnsiColor color = AnsiColor::GREEN;
        if (c.state.coherenceScore < 35) color = AnsiColor::RED;
        else if (c.state.coherenceScore < 65) color = AnsiColor::YELLOW;
        printColored(std::to_string(c.state.coherenceScore) + "%\n", color);
    }, "Quick view of centralized system stability percentage.");

    pipeline.registerCommand("reset", [](RuntimeContext& c, const std::string&) {
        c.engine->reset(c.state);
        printColored("[SYSTEM] Runtime matrices cleared. Returned to PAGE-0.\n", AnsiColor::YELLOW);
    }, "Return system to dormant baseline.");

    pipeline.registerCommand("toggle-ux", [](RuntimeContext& c, const std::string&) {
        c.config.kidMode = !c.config.kidMode;
        c.config.expertMode = !c.config.kidMode;
        if (c.config.kidMode) {
            printColored("[INTERFACE] KID MODE enabled. Friendly abstraction active.\n", AnsiColor::YELLOW);
        } else {
            printColored("[INTERFACE] EXPERT MODE enabled. Raw telemetry active.\n", AnsiColor::CYAN);
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
            printColored("Usage: codex search <term>\n", AnsiColor::YELLOW);
            return;
        }

        bool found = false;
        printColored("\n--- SYSTEM REGISTER INTERROGATION: KURFEW KULT CODEX ---\n", AnsiColor::MAGENTA);
        for (const auto& e : c.codexDatabase) {
            std::string keyLower = e.key;
            std::string contentLower = e.content;
            std::transform(keyLower.begin(), keyLower.end(), keyLower.begin(), ::tolower);
            std::transform(contentLower.begin(), contentLower.end(), contentLower.begin(), ::tolower);
            if (keyLower.find(qLower) != std::string::npos || contentLower.find(qLower) != std::string::npos) {
                printColored("[" + e.key + "]\n", AnsiColor::CYAN);
                std::cout << "  Abstract Mapping: " << e.content << "\n";
                printColored("  Verification:     " + e.citation + "\n\n", AnsiColor::YELLOW);
                found = true;
            }
        }
        if (!found) {
            printColored("No documented operational references found for query.\n", AnsiColor::RED);
        }
    }, "Query Kurfew Kult Codex v17.0 entries.");

    pipeline.registerCommand("telemetry", [](RuntimeContext& c, const std::string& args) {
        if (args != "export --json") {
            printColored("Usage: telemetry export --json\n", AnsiColor::YELLOW);
            return;
        }

        try { fs::create_directories("bin"); } catch (...) {}
        std::string path = "bin/telemetry_" + timestamp(true) + ".json";
        std::ofstream out(path);
        if (!out.is_open()) {
            printColored("[FILE] Could not open telemetry export path.\n", AnsiColor::RED);
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
        printColored("[SYSTEM] Telemetry export complete: " + path + "\n", AnsiColor::GREEN);
    }, "Export telemetry history as JSON.");

    pipeline.registerCommand("help", [&pipeline](RuntimeContext&, const std::string&) {
        pipeline.printHelp();
    }, "List available commands and descriptions.");

    pipeline.registerCommand("exit", [](RuntimeContext& c, const std::string&) {
        printColored("Decommissioning active Peristyle subgrids. Exiting context safely.\n", AnsiColor::CYAN);
        c.running = false;
    }, "Terminate the active orchestration session safely.");

    printColored("===============================================================\n", AnsiColor::CYAN);
    printColored(" KKOS v2.1 // KURFEW KULT CODEX // COHERENCE RUNTIME SHELL     \n", AnsiColor::CYAN);
    printColored("===============================================================\n", AnsiColor::CYAN);
    std::cout << "Log routing established at: " << ctx.logFilePath << "\n";
    std::cout << "Type 'help' to review structural orchestration controls.\n";

    std::string line;
    while (ctx.running) {
        std::cout << "\nkkos_admin@peristyle> ";
        if (!std::getline(std::cin, line)) break;
        pipeline.processLine(line);
    }

    return 0;
}
