#!/usr/bin/env -S scala-cli shebang

//> using scala 3.3.1
//> using dep com.lihaoyi::upickle:3.1.4

import java.net.{ StandardProtocolFamily, UnixDomainSocketAddress }
import java.nio.ByteBuffer
import java.nio.channels.SocketChannel
import scala.annotation.tailrec
import scala.sys.process.stringToProcess
import upickle.default.read
import upickle.default.write

def handleWorkspaceEvents(event: String, eventData: String): Unit = event match
    case "createworkspace" =>
        val workspaces = read[Array[Boolean]]("eww get workspace_content".!!)
        workspaces(eventData.toInt - 1) = true
        s"""eww update workspace_content="${write[Array[Boolean]](workspaces)}"""".run
    
    case "destroyworkspace" =>
        val workspaces = read[Array[Boolean]]("eww get workspace_content".!!)
        workspaces(eventData.toInt - 1) = false
        s"""eww update workspace_content="${write[Array[Boolean]](workspaces)}"""".run
    
    case _ => /* Do not listen for other types of events */

@tailrec
def listenForChanges: Unit =
    val buffer = ByteBuffer.allocate(bytes)
    val bytesRead: Int = channel.read(buffer)
    
    if bytesRead > 0 then 
        val messageInBytes = Array.fill[Byte](bytesRead)(0)  
        buffer.flip
        buffer.get(messageInBytes)
    
        val content = String(messageInBytes)
        val messages: Array[String] = content.split("\n")
        messages
            .map(elem => elem.trim.split(">>"))
            .filter(elem => elem.length > 1)
            .foreach(elem => handleWorkspaceEvents(elem(0), elem(1)))
    
    Thread.sleep(100)
    listenForChanges

val bytes = 8192
val hyprInstance = sys.env("HYPRLAND_INSTANCE_SIGNATURE")
val socketPath = s"/tmp/hypr/$hyprInstance/.socket2.sock"
val socketAddress = UnixDomainSocketAddress.of(socketPath)
val channel = SocketChannel.open(StandardProtocolFamily.UNIX)

channel.connect(socketAddress);
listenForChanges