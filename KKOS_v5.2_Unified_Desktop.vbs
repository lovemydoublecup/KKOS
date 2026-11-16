Set shell = CreateObject("WScript.Shell")
launcher = """" & CreateObject("Scripting.FileSystemObject").GetAbsolutePathName("KKOS_v5.2_Unified_Desktop.cmd") & """
shell.Run launcher, 0, False
