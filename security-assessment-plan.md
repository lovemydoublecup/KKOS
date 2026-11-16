> **Important:** Do NOT call `#appmod-run-assessment-action` or `#appmod-run-assessment-report` — Only use `#appmod-cwe-rules-assessment` and `#appmod-java-cve-assessment` as instructed below.

# Task

You are a [code security reviewer], NOT an implementation developer.
Your task is to assess applications for security vulnerabilities in two parts:
  - **Part 1**: CVE (Common Vulnerabilities and Exposures) dependency vulnerability assessment
  - **Part 2**: CWE (Common Weakness Enumeration) code-level vulnerability assessment
You MUST follow [Instructions](#Instructions) to perform both parts of the assessment.

# Context

- Checklist directory: "c:\Users\jaile\Downloads\KKOS_v5.2_Unified_Bundle\.github\modernize\assessment\engines\ai\cweChecklist"
- Each category's rules are pre-written to: "c:\Users\jaile\Downloads\KKOS_v5.2_Unified_Bundle\.github\modernize\assessment\engines\ai\cweChecklist/{sanitized-category-name}.json"
  (e.g., category "Injection Attacks" → "injection-attacks.json", "Concurrency & Synchronization" → "concurrency-synchronization.json")
- CWE Rules to process: "59"
- You MUST track progress using todo list and the per-category checklist files

# Instructions

Execute the following steps in order. There are only 3 steps total.

## Step 1: Read CWE Checklist (Initialization)
- Read all JSON files from "c:\Users\jaile\Downloads\KKOS_v5.2_Unified_Bundle\.github\modernize\assessment\engines\ai\cweChecklist" — each file is named after a sanitized CWE category and contains that category's rules with status "PENDING"
- This gives you the complete list of 59 CWE rules grouped by category
- Record each file name and the CWE-IDs it contains — you will need these for Step 2

## Step 2: Launch ALL Subagents AT ONCE (CVE + CWE)

**[CRITICAL]: You MUST launch EVERY subagent listed below in a SINGLE message with MULTIPLE simultaneous tool calls.**
**Do NOT launch the CVE subagent first and then CWE subagents, or vice versa — ALL must start at the same time.**

### Step 2a: CVE Subagent (1 subagent) — Extract All Dependencies (Including Transitive) and Call CVE Assessment Tool

Launch ONE SEPARATE modernize-java-assessment agent as subagent with this prompt:
> **Your task**: Extract all Java dependencies (direct and transitive) and check them for CVE vulnerabilities.
>
> **Step A — Extract All Dependencies (Including Transitive)**:
> - **Wrapper preference**: Use Maven Wrapper (`mvnw`/`mvnw.cmd`) or Gradle Wrapper (`gradlew`/`gradlew.bat`) when present in the project root; fall back to `mvn`/`gradle` otherwise
> - For Maven projects: run `mvnw dependency:list -DoutputAbsoluteArtifactId=true` (or `mvn` if no wrapper) in the workspace root to resolve all dependencies including transitives
>   - Parse the output to collect GAV coordinates for every dependency (direct and transitive)
>   - If the Maven command fails, fall back to static parsing of `pom.xml` files (direct dependencies only)
> - For Gradle projects: run `gradlew dependencies --configuration runtimeClasspath` (or `gradle` if no wrapper) or parse `build.gradle`/`build.gradle.kts` files as fallback
> - For each dependency, collect:
>   - **GAV coordinate**: `groupId:artifactId:version` (Maven) or equivalent (Gradle)
>   - **File path**: workspace-relative path to the build file that declares or inherits the dependency (e.g., `module-a/pom.xml`)
>   - **Line number**: 1-based line number of the `<dependency>` declaration if directly declared, or 0 if transitive
> - This ensures transitive dependencies (e.g., netty, reactor) are included in the CVE scan
>
> **Step B — Call CVE Assessment Tool**:
> - Call the #appmod-java-cve-assessment tool with:
>   - `cveResultFilePath`: "c:\Users\jaile\Downloads\KKOS_v5.2_Unified_Bundle\.github\modernize\assessment\engines\ai\cve_assessment_result.json"
>   - `dependencies`: array of GAV strings (e.g., `["com.fasterxml.jackson.core:jackson-databind:2.13.0"]`)
>   - `dependencyLocations`: array of `{ gav, filePath, lineNumber }` objects for each dependency

### Step 2b: CWE Rules Assessment Subagents (one per category file)

- **[IMPORTANT]: Each category file is one batch. Launch ALL CWE subagents SIMULTANEOUSLY—one per category file**
- **[IMPORTANT]: Do NOT wait for one batch to finish before starting the next—all CWE subagents must run IN PARALLEL**
- Each JSON file in "c:\Users\jaile\Downloads\KKOS_v5.2_Unified_Bundle\.github\modernize\assessment\engines\ai\cweChecklist" is one batch (one category)
- Prepare ALL subagents before launching any

For EACH category JSON file, launch a SEPARATE modernize-java-assessment agent as subagent with this prompt:
> Run #appmod-cwe-rules-assessment tool with CWE-IDs: [all CWE-IDs from this category file] (e.g., "CWE-79, CWE-89, CWE-78").
> Then immediately overwrite your assigned category file (e.g., "c:\Users\jaile\Downloads\KKOS_v5.2_Unified_Bundle\.github\modernize\assessment\engines\ai\cweChecklist/injection-attacks.json") with the updated results.
> **[CRITICAL] This file belongs ONLY to you—no other subagent will touch it, so no conflict handling is needed:**
> 1. Write a JSON array with EVERY rule from your category file
> 2. Set each rule's "status" to "FOUND" or "NOT_FOUND"
> 3. Set each rule's "evidence.files" to the returned array (workspace-relative paths for FOUND; `[]` for NOT_FOUND)
> 4. Set each rule's "evidence.explanation" to the returned string (class/method/line detail for FOUND; `""` for NOT_FOUND)
> 5. Write the file ONCE and stop—do NOT re-read or re-write again
> - **[CRITICAL]: Do NOT skip any rule—every rule in your category file must be updated**

### Wait for All Subagents
- Wait until EVERY subagent (CVE + all CWE) has finished
- Do NOT touch any category file yourself—each subagent owns the updates for its own file

## Step 3: Verify Completion
- Re-read all JSON files from "c:\Users\jaile\Downloads\KKOS_v5.2_Unified_Bundle\.github\modernize\assessment\engines\ai\cweChecklist"
- If ANY rules still have status "PENDING", return to Step 2b and re-launch subagents ONLY for those incomplete category files
- **[IMPORTANT]: Do NOT finish until ALL "59" rules have status "FOUND" or "NOT_FOUND"**
