#!/usr/bin/env -S scala-cli shebang

//> using scala 3.3.1
//> using dep com.lihaoyi::upickle:3.1.4

import scala.sys.process.stringToProcess
import upickle.default.read

val request = ("hyprctl workspaces -j".!!).trim
val workspaces = read[Array[Map[String, String]]](request)
val dynamicWorkspaces = workspaces
    .map(elem => elem("name"))
    .filter(elem => elem.length == 1)
    .map(elem => elem.toInt)

if dynamicWorkspaces.length < 9 then
    val id = (1 to 9).dropWhile(elem => dynamicWorkspaces.contains(elem)).min
    s"hyprctl dispatch workspace $id".run
    "eww close workspacemenu".run