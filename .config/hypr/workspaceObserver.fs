#!/usr/bin/env scriptisto

(*
    scriptisto-begin
    script_src: Program.fs
    build_cmd: dotnet publish hello.fsproj
    target_bin: ./out/hello
    files:
        - path: hello.fsproj
          content: |
            <Project Sdk="Microsoft.NET.Sdk">
                <PropertyGroup>
                    <OutputType>Exe</OutputType>
                    <TargetFramework>net8.0</TargetFramework>
                    <PublishAot>true</PublishAot>
                    <PublishDir>out</PublishDir>
                    <CopyOutputSymbolsToPublishDirectory>false</CopyOutputSymbolsToPublishDirectory>
                </PropertyGroup>
                <ItemGroup>
                    <Compile Include="Program.fs" />
                </ItemGroup>
                <ItemGroup>
                    <PackageReference Include="Fli" Version="1.111.10" />
                </ItemGroup>
            </Project>
    scriptisto-end
*)

open Fli
open FSharp.Data
open System.Text.Json
open System.Threading

let serializeArray (nums: array<int32>): string =
    "[" + (nums |> Array.map string |> String.concat ",") + "]"

[<TailCall>]
let rec trackWorkspacesInUse (previousWorkspacesInUse: array<int32>) : Unit =
    let mutable thereWasChange = false

    use workspacesJson =
        cli {
            Exec "hyprctl"
            Arguments "workspaces -j"
        }
        |> Command.execute
        |> Output.toText
        |> JsonDocument.Parse

    let workspaces =
        Seq.cast<JsonElement> (workspacesJson.RootElement.EnumerateArray())
        |> Seq.map (fun entry -> entry.GetProperty("id").GetInt32())
        |> Seq.toArray

    if workspaces <> previousWorkspacesInUse then
        printfn $"{serializeArray workspaces}"
        thereWasChange <- true

    Thread.Sleep(50)

    trackWorkspacesInUse (
        if thereWasChange then
            workspaces
        else
            previousWorkspacesInUse
    )

[<TailCall>]
let rec trackActiveWorkspace (previousActiveWorkspace: int32) : Unit =
    let mutable thereWasChange = false

    use activeWorkspaceJson =
        cli {
            Exec "hyprctl"
            Arguments "activeworkspace -j"
        }
        |> Command.execute
        |> Output.toText
        |> JsonDocument.Parse

    let activeWorkspace = activeWorkspaceJson.RootElement.GetProperty("id").GetInt32()

    if activeWorkspace <> previousActiveWorkspace then
        printfn $"{activeWorkspace}"
        thereWasChange <- true

    Thread.Sleep(50)

    trackActiveWorkspace (
        if thereWasChange then
            activeWorkspace
        else
            previousActiveWorkspace
    )

[<EntryPoint>]
let main args : int32 =
    assert (args.Length = 1)

    match args[0] with
    | "--active" -> trackActiveWorkspace 1
    | "--in-use" -> trackWorkspacesInUse [| 1 |]
    | _ -> ()

    0
