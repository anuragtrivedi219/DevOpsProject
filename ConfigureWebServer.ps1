Configuration ConfigureWebServer {
    Node "localhost" {

        WindowsFeature IIS {
            Name   = "Web-Server"
            Ensure = "Present"
        }

        WindowsFeature IISMgmtConsole {
            Name   = "Web-Mgmt-Console"
            Ensure = "Present"
        }
    }
}

ConfigureWebServer
Start-DscConfiguration -Path .\ConfigureWebServer -Wait -Verbose -Force
