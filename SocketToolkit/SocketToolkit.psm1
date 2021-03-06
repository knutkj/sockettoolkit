﻿function New-Socket {

    #
    # .SYNOPSIS
    # Creates a new socket.
    #
    
    [CmdletBinding()]
    param (

        #
        # Creates a none blocking socket.
        #
        [Parameter()]
        [switch] $NoneBlocking
    )
    
    process {
        $addressFamily = [Net.Sockets.AddressFamily]::InterNetwork
        Write-Verbose -Message "Using address family $addressFamily."
        $socketType = [Net.Sockets.SocketType]::Stream
        Write-Verbose -Message "Using socket type $socketType."
        $protocolType = [Net.Sockets.ProtocolType]::Tcp
        Write-Verbose -Message "Using protocol type $protocolType."
        New-Object `
            -TypeName Net.Sockets.Socket `
            -ArgumentList $addressFamily, $socketType, $protocolType `
            -Property @{ Blocking = -not $NoneBlocking }
    }
}

function Connect-Socket {
    
    #
    # .SYNOPSIS
    # Connects a specified socket to the specified end point. If no socket
    # is specified a new socket will be created. A new socket will do a none
    # blocking connect if the NoneBlocking switch is used.
    #
    
    [CmdletBinding(
        DefaultParameterSetName = 'Address'
    )]
    param (
    
        #
        # The socket to connect. If not specified a new socket will be created. 
        #
        [Parameter(
            ParameterSetName = 'SocketAddress',
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = 'SocketEndPoint',
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Net.Sockets.Socket] $Socket,

        #
        # The address to connect to. Will be resolved by DNS.
        #
        [Parameter(
            ParameterSetName = 'Address',
            Position = 0,
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = 'SocketAddress',
            Position = 1,
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string] $Address,
    
        #
        # The port to connect to.
        #
        [Parameter(
            ParameterSetName = 'Address',
            Position = 1,
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            ParameterSetName = 'SocketAddress',
            Position = 2,
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [int] $Port,
        
        #
        # The IP end point to connect to. If you use the Address parameter the
        # address will be resolved by DNS. Use this parameter if you know the
        # IP, resolve the IP yourself or need to prevent DNS resolving for
        # other reasons.
        #
        [Parameter(
            ParameterSetName = 'EndPoint',
            Position = 0,
            Mandatory = $true            
        )]
        [Parameter(
            ParameterSetName = 'SocketEndPoint',
            Position = 1,
            Mandatory = $true            
        )]
        [Net.IPEndPoint] $EndPoint,
        
        #
        # Makes a none blocking connect.
        #
        [Parameter(ParameterSetName = 'Address')]
        [Parameter(ParameterSetName = 'EndPoint')]
        [switch] $NoneBlocking
    )
    
    process {
        
        if ($Socket -eq $null) {
            Write-Verbose -Message 'Creating new socket...'
            $Socket = New-Socket -NoneBlocking: $NoneBlocking
        }
        Write-Verbose -Message "Resolving address $Address..."
        $hostEntry = [Net.Dns]::Resolve($Address)
        $ipAddress = $hostEntry.AddressList[0]
        Write-Verbose -Message "Address resolved to IP $ipAddress."
        $endPoint = New-Object `
            -TypeName Net.IPEndPoint `
            -ArgumentList $ipAddress, $Port
        Write-Verbose -Message 'Socket connecting...'
        try {
            $Socket.Connect($endPoint)
            Write-Verbose -Message 'Socket connected.'
            $Socket
        } catch {
            $Socket
        }
    }
}

function Disconnect-Socket {

    #
    # .SYNOPSIS
    # Disconnects the specified socket.
    #
    
    [CmdletBinding()]
    param (
        #
        # The socket to disconnect.
        #
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [Net.Sockets.Socket] $Socket
    )
    
    process {        
        $Socket.Shutdown([Net.Sockets.SocketShutdown]::Both)
        $Socket.Close()
    }
}