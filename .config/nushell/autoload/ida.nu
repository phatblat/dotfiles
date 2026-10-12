# ida - Launch IDA with elevated privileges
export def ida [...args: string] {
    let ida_path = "/Applications/IDA Pro 7.5"
    if not ($ida_path | path exists) {
        print "IDA is not installed"
        error make { msg: "IDA is not installed" }
    }
    ^sudo $"($ida_path)/idabin/ida64" ...$args
}
