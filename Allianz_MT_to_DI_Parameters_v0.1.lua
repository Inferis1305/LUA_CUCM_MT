--[[
CUCM SIP Normalization Script - Display Name Prefix & Location-Based Number Transformation
This script automatically adds a configurable prefix to display names in SIP headers (From, Remote-Party-ID, etc.) 
and transforms international numbers based on location mappings from X-Cisco-Location-Info headers.
Created by Georgi for dynamic trunk parameter configuration.
--]]

M = {}

-- Get parameter values using CUCM scriptParameters.getValue() function
local displayNamePrefix = scriptParameters.getValue("prefixDisplayNameValue") or ""
local locationPrefixMap1 = scriptParameters.getValue("LocationPrefixMap1") or ""
local locationPrefixMap2 = scriptParameters.getValue("LocationPrefixMap2") or ""
local locationPrefixMap3 = scriptParameters.getValue("LocationPrefixMap3") or ""
local locationPrefixMap4 = scriptParameters.getValue("LocationPrefixMap4") or ""
local locationPrefixMap5 = scriptParameters.getValue("LocationPrefixMap5") or ""

-- Allow access to custom SIP headers
M.allowHeaders = {
    "X-Cisco-Location-Info",
    "X-BroadWorks-Correlation-Info"
}

trace.enable()

-- Function to parse location prefix mappings
local function parseLocationMappings()
    local mappings = {}
    
    -- Helper function to parse a single mapping parameter
    local function parseMapping(paramName, paramValue)
        if paramValue ~= "" then
            local locationId, prefix = paramValue:match("^([^,]+),(.+)$")
            if locationId and prefix then
                -- Trim whitespace from locationId and prefix
                locationId = locationId:match("^%s*(.-)%s*$")
                prefix = prefix:match("^%s*(.-)%s*$")
                mappings[locationId] = prefix
                trace.format("Loaded %s: %s -> %s", paramName, locationId, prefix)
            else
                trace.format("Invalid format for %s: %s", paramName, paramValue)
            end
        end
    end
    
    -- Parse all LocationPrefixMap parameters
    parseMapping("LocationPrefixMap1", locationPrefixMap1)
    parseMapping("LocationPrefixMap2", locationPrefixMap2)
    parseMapping("LocationPrefixMap3", locationPrefixMap3)
    parseMapping("LocationPrefixMap4", locationPrefixMap4)
    parseMapping("LocationPrefixMap5", locationPrefixMap5)
    
    -- Log total mappings loaded
    local count = 0
    for _ in pairs(mappings) do count = count + 1 end
    trace.format("Total location mappings loaded: %d", count)
    
    return mappings
end

function M.inbound_INVITE(msg)
    trace.format("--- Running Georgi script 6 dynamic mapping with 6 LocationPrefixMap  ---")

    -- Log the parameter value
    trace.format("prefixDisplayNameValue: %s", displayNamePrefix)

    -- Apply prefixDisplayNameValue to all INVITEs (if not empty)
    if displayNamePrefix ~= "" then
        trace.format("Applying display name prefix to all INVITEs.")

        local headersToModify = {
            "From",
            "Remote-Party-ID",
            "P-Preferred-Identity",
            "P-Asserted-Identity"
        }

        local function prefixDisplayName(headerName)
            local hdr = msg:getHeader(headerName)
            if hdr then
                local displayName = hdr:match('^"?(.-)"?%s*<')
                if displayName and displayName ~= "" then
                    local newDisplayName = '"' .. displayNamePrefix .. displayName .. '"'
                    local modifiedHeader = hdr:gsub('^"?.-"?<', newDisplayName .. " <")
                    msg:modifyHeader(headerName, modifiedHeader)
                    trace.format("Modified %s header: %s", headerName, modifiedHeader)
                else
                    trace.format("No display name found in %s header. Skipping.", headerName)
                end
            else
                trace.format("%s header not found. Skipping.", headerName)
            end
        end

        for _, header in ipairs(headersToModify) do
            prefixDisplayName(header)
        end
    else
        trace.format("prefixDisplayNameValue is empty. Skipping display name modifications.")
    end

    -------------------------------------------------------------------------
    -- Dynamic Location ID to Prefix mapping logic
    -------------------------------------------------------------------------
    local locationMappings = parseLocationMappings()
    local locationHeader = msg:getHeader("X-Cisco-Location-Info")

    if locationHeader then
        trace.format("X-Cisco-Location-Info header found: %s", locationHeader)

        local extractedId = string.match(locationHeader, "^([^;]+)")
        if extractedId then
            local trimmedId = string.gsub(extractedId, "^%s*(.-)%s*$", "%1")
            trace.format("Extracted Location ID: %s", trimmedId)

            -- Check if this location ID has a configured prefix mapping
            local numberPrefix = locationMappings[trimmedId]
            if numberPrefix then
                trace.format("Location ID matches configured mapping. Using prefix: %s", numberPrefix)

                local method, ruri, ver = msg:getRequestLine()
                trace.format("Request URI found is: %s", tostring(ruri))

                local i = string.find(ruri, ":")
                local j = string.find(ruri, "@", i+1)

                local calledNumber = string.sub(ruri, i+1, j-1)
                trace.format("Called party number: %s", tostring(calledNumber))

                local new_calledNumber = string.gsub(calledNumber, "%+", numberPrefix)
                local new_ruri = string.gsub(ruri, calledNumber, new_calledNumber, 1)

                msg:setRequestUri(new_ruri)
                trace.format("New Request URI set to: %s", tostring(new_ruri))
            else
                trace.format("No prefix mapping found for Location ID: %s", trimmedId)
            end
        else
            trace.format("Failed to extract Location ID from header.")
        end
    else
        trace.format("X-Cisco-Location-Info header not present. Skipping RURI logic.")
    end
end

return M
