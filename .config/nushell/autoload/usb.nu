# Dependencies:
#   functions: none
#   builtins:  from json get default each sort-by reject insert append flatten compact str join is-empty is-not-empty where enumerate length match error make ansi is-terminal
#   externals: system_profiler

# Recursively reshape raw system_profiler USB nodes into stable records
def usb-normalize [nodes: list] {
    $nodes
    | each {|n|
        {
            name:       ($n._name? | default "Unknown")
            vendor:     ($n.USBDeviceKeyVendorName? | default null)
            speed:      ($n.USBDeviceKeyLinkSpeed? | default null)
            location:   ($n.USBKeyLocationID? | default null)
            vendor_id:  ($n.USBDeviceKeyVendorID? | default null)
            product_id: ($n.USBDeviceKeyProductID? | default null)
            serial:     (match ($n.USBDeviceKeySerialNumber? | default null) { "Not Provided" => null, $s => $s })
            power:      ($n.USBDeviceKeyPowerAllocation? | default null)
            hardware:   ($n.USBKeyHardwareType? | default null)
            tunneled:   (($n.USBDeviceKeyUSB4Tunnel? | default "No") == "Yes")
            children:   (usb-normalize ($n._items? | default []))
        }
    }
    | sort-by {|n| $n.location | default "" }
}

# Flatten the device tree into rows carrying depth and owning bus
def usb-flatten [nodes: list, depth: int, bus: any] {
    $nodes
    | each {|n|
        let bus = if $depth == 0 { $n.name } else { $bus }
        [($n | reject children | insert depth $depth | insert bus $bus)]
        | append (usb-flatten $n.children ($depth + 1) $bus)
    }
    | flatten
}

# Build the text for a single tree line
def usb-label [node: record, long: bool, color: bool] {
    let fields = if $long {
        [
            $node.vendor
            $node.speed
            $node.location
            (if $node.vendor_id != null { $"($node.vendor_id):($node.product_id)" })
            $node.hardware
            $node.power
            (if $node.tunneled { "USB4 tunnel" })
            $node.serial
        ]
    } else {
        [$node.vendor $node.speed]
    }
    # Host controllers report no vendor or link speed; show the bus type instead
    let fields = ($fields | compact)
    let fields = if ($fields | is-empty) { [$node.hardware] | compact } else { $fields }

    if ($fields | is-empty) {
        $node.name
    } else if $color {
        $"($node.name)  (ansi dark_gray)($fields | str join '  ')(ansi reset)"
    } else {
        $"($node.name)  ($fields | str join '  ')"
    }
}

# Recursively render box-drawing tree lines
def usb-render [nodes: list, prefix: string, long: bool, color: bool] {
    let last = (($nodes | length) - 1)
    $nodes
    | enumerate
    | each {|it|
        let is_last = ($it.index == $last)
        let branch = if $is_last { "└── " } else { "├── " }
        let pad    = if $is_last { "    " } else { "│   " }
        [$"($prefix)($branch)(usb-label $it.item $long $color)"]
        | append (usb-render $it.item.children $"($prefix)($pad)" $long $color)
    }
    | flatten
}

# Show connected USB devices as a tree
export def usb [
    --all (-a)   # Include host controllers with nothing attached
    --long (-l)  # Add location ID, VID:PID, hardware type, power, tunneling, and serial
    --data (-d)  # Return a flat table of devices instead of the rendered tree
] {
    let payload = (
        ^system_profiler -json SPUSBHostDataType
        | from json
        | get -o SPUSBHostDataType
    )
    if $payload == null {
        error make { msg: "usb: system_profiler returned no SPUSBHostDataType payload" }
    }

    let buses = (usb-normalize $payload)
    let buses = if $all { $buses } else { $buses | where {|b| $b.children | is-not-empty } }

    if $data {
        return (usb-flatten $buses 0 null)
    }

    let lines = (usb-render $buses "" $long (is-terminal --stdout))
    let bus_count = ($buses | length)
    let device_count = (($lines | length) - $bus_count)
    let summary = $"($bus_count) (if $bus_count == 1 { 'bus' } else { 'buses' }), ($device_count) (if $device_count == 1 { 'device' } else { 'devices' })"

    ["USB"] | append $lines | append ["" $summary] | str join "\n"
}
