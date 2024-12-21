#!/usr/bin/env scriptisto

(*
    scriptisto-begin
    script_src: workspaceSwitch.fs
    build_cmd: dotnet publish workspaceSwitch.fsproj
    target_bin: ./out/workspaceSwitch
    files:
        - path: workspaceSwitch.fsproj
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
                    <Compile Include="workspaceSwitch.fs" />
                </ItemGroup>
                <ItemGroup>
                    <PackageReference Include="Fsharp.Data" Version="6.4.0" />
                    <PackageReference Include="Fli" Version="1.111.10" />
                </ItemGroup>
            </Project>
    scriptisto-end
*)

open Fli
open FSharp.Data
open FSharp.Data.JsonExtensions

type Direction =
    | Left
    | Right

let changeToWorkspaceIfPossible (dir: Direction): Unit =
    let workspacesJson =
        cli {
            Exec "hyprctl"
            Arguments "workspaces -j"
        }
        |> Command.execute
        |> Output.toText
        |> JsonValue.Parse

    let workspaces =
        workspacesJson.AsArray()
        |> Array.map (fun ws -> ws?id.AsInteger())

    if workspaces.Length > 1 then
        let activeWorkspaceJson =
            cli {
                Exec "hyprctl"
                Arguments "activeworkspace -j"
            }
            |> Command.execute
            |> Output.toText
            |> JsonValue.Parse

        let activeWorkspace = activeWorkspaceJson?id.AsInteger()

        match dir with
        | Left when activeWorkspace > 1 ->
            cli {
                Exec "hyprctl"
                Arguments $"dispatch workspace {activeWorkspace - 1}"
            }
            |> Command.execute
            |> ignore


        | Right when activeWorkspace < workspaces.Length -> 
            cli {
                Exec "hyprctl"
                Arguments $"dispatch workspace {activeWorkspace + 1}"
            }
            |> Command.execute
            |> ignore

        | _ -> ()

[<EntryPoint>]
let main args : int32 =
    if args.Length <> 1 then
        ()

    else
        match args[0] with
        | "--left" -> changeToWorkspaceIfPossible (Left)
        | "--right" -> changeToWorkspaceIfPossible (Right)
        | _ -> ()
    
    0
