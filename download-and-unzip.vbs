' download-and-unzip.vbs - download a zip file from the web and unzip its contents to the local filesystem

Dim debug
debug = False ' Will be set True if /DEBUG was specified

Dim fso: Set fso = CreateObject("Scripting.FileSystemObject")


Sub Usage()
    WScript.Echo("Usage:")
    WScript.Echo("   " + WScript.ScriptName + " [/DEBUG] <url> <dir>")
    WScript.Echo()
    WScript.Echo("      /DEBUG    if specified, print extra information showing what this scipt is doing")
    WScript.Echo("      <url>     the URL to download from; the URL is expected to point to a .zip file")
    WScript.Echo("      <dir>     the parent directory under which to unzip the file")
    WScript.Quit(1)
End Sub

Sub DebugPrint(msg)
    If debug Then
        WScript.Echo("[DOWNLOAD] " + msg)
    End If
End Sub


Sub Download(url, zip)
    DebugPrint "Attempting to download '" + url + "'"
    Dim xmlHTTP: Set xmlHTTP = CreateObject("Microsoft.XMLHTTP")
    xmlHTTP.Open "GET", url, False
    xmlHTTP.Send
    If xmlHTTP.Status = 200 Then
    Else
        WScript.Echo("Failed downloading '" + url + "': " + xmlHTTP.statusText)
        WScript.Quit(1)
    End If

    DebugPrint "Download succeeded, saving to '" + zip + "'"
    Dim stream: Set stream = CreateObject("Adodb.Stream")
    With stream
        .Type = 1 '//binary
        .Open
        .Write xmlHTTP.responseBody
        .SaveToFile zip, 2 '//overwrite
    End With
End Sub


Sub Unzip(zip, dir)
    dir = Replace(dir + "\", "\\", "\")

    'If the extraction location does not exist create it.
    If Not fso.FolderExists(dir) Then
        DebugPrint "Creating parent folder '" + dir + "'"
        fso.CreateFolder(dir)
    End If

    DebugPrint "Unzipping archive '" + zip + "' to '" + dir + "'"
    With CreateObject("Shell.Application")
        Dim zipItems: Set zipItems = .NameSpace(zip).Items
        Dim extractTo: Set extractTo = .Namespace(dir)
        extractTo.CopyHere(zipItems)
    End With
End Sub


' MAIN SCRIPT BEGINS HERE
' -----------------------

Dim url, dir
For Each arg In WScript.Arguments
    If arg = "/?" Then
        Usage
        WScript.Quit(1)
    ElseIf arg = "/DEBUG" Then
        debug = True
    ElseIf arg <> "" And url = "" Then
        url = arg
    ElseIf arg <> "" And dir = "" Then
        dir = arg
    Else
        WScript.Echo("Invalid argument '" + arg + "'")
        WScript.Quit(1)
    End If
Next

Dim tempFolder: tempFolder = fso.GetSpecialFolder(2)
Dim zip: zip = tempFolder + "\download-and-unzip.zip"
Download url, zip
Unzip zip, dir

If fso.FileExists(zip) Then
    DebugPrint "Deleting temporary file '" + zip + "'"
    fso.DeleteFile(zip)
End If
