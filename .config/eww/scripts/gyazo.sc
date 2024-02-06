#!/usr/bin/env -S scala-cli shebang

//> using scala 3.3.1
//> using dep com.lihaoyi::upickle:3.1.4

import java.nio.file.{ Files, Paths }
import scala.collection.immutable.Map
import scala.sys.process.stringToProcess
import upickle.default.read

val config = Map(
    "open_browser" -> "xdg-open",
    "print_screen" -> "grim -g",
    "host"         -> "https://upload.gyazo.com/api/upload",
    "env_var"      -> "GYAZO_API_KEY"
)

// =====================================
// Check wether a valid API key is set
// =====================================

val apiKey = sys.env.get(config("env_var")) match {
    case Some(value) => value
    case None        => "" 
}

if apiKey.isEmpty then
    sys.exit(0)

// ===========================================
// Load selected area from arguments
// Then create a screenshot in tmp directory
// ===========================================

val selectedArea = args(0)
val tmpFile = Paths.get(s"/tmp/image_upload${ProcessHandle.current.pid}.png")
s"""${config("print_screen")} "$selectedArea" ${tmpFile.toString}""".!

if Files.exists(tmpFile) == false then
    sys.exit(0)

// ====================================================
// Send POST request to Gyazo and inspect its results
// ====================================================

val request = s"""curl -is ${config("host")} -F "access_token=$apiKey" -F "imagedata=@${tmpFile.toString}""""
val response: Array[String] = (request.!!).split("\n\n")
val header: String = response(0)

if header.contains("HTTP/2 200") == false then
    Files.delete(tmpFile)
    sys.exit(0)

val body = read[Map[String, String]](response(1))

// ===================================
// Open image inside default browser
// Then clean up local image
// ===================================

s"""${config("open_browser")} "${body("permalink_url")}"""".run
Files.delete(tmpFile)