require "http/server"
require "json"
require "psutil"

module Canary
  VERSION = "0.1.0"

  def self.host
    info = Psutil.host_info

    {
      "hostname" => info.hostname,
      "uptime" => info.uptime,
      "boot_time" => info.boot_time,
      "procs" => info.procs,
      "os" => info.os,
      "platform" => info.platform,
      "platform_version" => info.platform_version,
      "kernel_version" => info.kernel_version,
      "host_id" => info.host_id,
      "arch" => info.arch,
    }
  end

  def self.cpu
    result = Hash(String, Hash(String, Float64)).new

    Psutil.cpu_times.map do |info|
      result[info.cpu] = {
        "user" => info.user,
        "system" => info.system,
        "idle" => info.idle,
      }
    end

    result
  end

  def self.memory
    info = Psutil.virtual_memory

    {
      "available" => info.available,
      "total" => info.total,
      "used" => info.used,
    }
  end

  def self.loadavg
    info = Psutil.load_avg

    {
      "1min" => info.load1,
      "5min" => info.load5,
      "15min" => info.load15,
    }
  end

  def self.net
    result = Hash(String, Hash(String, Hash(String, UInt64))).new

    Psutil.net_io_counters.map do |info|
      result[info.name] = {
        "bytes" => {
          "in" => info.bytes_recv,
          "out" => info.bytes_sent,
        },
        "packets" => {
          "in" => info.packets_recv,
          "out" => info.packets_sent,
        },
        "errors" => {
          "in" => info.errin,
          "out" => info.errout,
        },
        "drops" => {
          "in" => info.dropin,
          "out" => info.dropout,
        },
        "fifo" => {
          "in" => info.fifoin,
          "out" => info.fifoout,
        },
      }
    end

    result
  end

  server = HTTP::Server.new(
    [
      HTTP::ErrorHandler.new,
      HTTP::LogHandler.new,
      HTTP::CompressHandler.new,
    ]
  ) do |context|

    data = {
      "host" => host,
      "loadavg" => loadavg,
      "memory" => memory,
      "cpu" => cpu,
      "net" => net,
    }.to_json

    context.response.content_type = "application/json"
    context.response.print data
  end

  address = server.bind_tcp Socket::IPAddress.new("0.0.0.0", 80)

  Signal::INT.trap {
    puts "Exiting from Keyboard Interrupt..."
    server.close
    exit
  }

  puts "Listening on http://#{address}"
  server.listen

end
