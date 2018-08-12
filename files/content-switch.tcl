when HTTP_REQUEST {
    if { ([HTTP::header User-Agent] contains "iphone") or ([HTTP::header User-Agent] contains "Android") }{
        node 10.1.0.217:8002
    }
}