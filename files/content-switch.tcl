when HTTP_REQUEST {
    if { ([HTTP::header User-Agent] contains "iphone") or ([HTTP::header User-Agent] contains "Android") }{
        HTTP::respond 200 content {
            <html>
                <head>
                    <title>iRule Page</title>
                </head>
                <body>
                    Phone user
                </body>
            </html>
        }
    }
}