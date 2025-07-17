# CUCM SIP Normalization Script

## Display Name Prefix & Location-Based Number Transformation

[![CUCM Compatible](https://img.shields.io/badge/CUCM-Compatible-green.svg)](https://www.cisco.com/c/en/us/products/unified-communications/index.html)
[![Lua](https://img.shields.io/badge/Language-Lua-blue.svg)](https://www.lua.org/)

A dynamic CUCM SIP normalization script that automatically adds configurable prefixes to display names and transforms international numbers based on location mappings from X-Cisco-Location-Info headers.

## 🚀 Features

- **Dynamic Display Name Prefixing**: Automatically adds configurable prefixes to SIP identity headers
- **Location-Based Number Transformation**: Transforms international numbers based on location mappings
- **Fallback Mechanism**: Uses default prefix when specific location mappings are not found
- **Comprehensive Logging**: Detailed trace output for debugging and monitoring
- **Multiple Header Support**: Modifies From, Remote-Party-ID, P-Preferred-Identity, and P-Asserted-Identity headers

## 📋 Prerequisites

- Cisco Unified Communications Manager (CUCM)
- SIP Trunk with Normalization Script support
- Lua scripting enabled on CUCM

## ⚙️ Configuration Parameters

### Required CUCM Script Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `prefixDisplayNameValue` | String | Prefix to add to display names | `"MT_EMEA_Default:"` |
| `LocationPrefixMap1` | String | Location ID to prefix mapping | `"a8f4e2c1-92d7-4b5e-a3c6-1f7e8d9c4b2a,001"` |
| `LocationPrefixMap2` | String | Location ID to prefix mapping | `"c144543e-66d3-468f-9639-37ec74309ff0,0044"` |
| `LocationPrefixMap3` | String | Location ID to prefix mapping | `"f7b2d8e4-3a1c-4f9e-b5d7-9e2c8f4a6b1d,0081"` |
| `LocationPrefixMap4` | String | Location ID to prefix mapping | `"d9e5c3a7-4f2b-4e8c-a1d6-7b9e3c5f2a8d,0049"` |
| `LocationPrefixMap5` | String | Location ID to prefix mapping | `"b3c7f1e9-5d2a-4c8f-9e1b-6a4d7c9e2f5b,0061"` |
| `LocationPrefixDefault` | String | Default prefix for unmapped locations | `"*99"` |

### Parameter Format

**Location Prefix Mapping Format:**
```
"LocationID,Prefix"
```

**Examples:**
- `"a8f4e2c1-92d7-4b5e-a3c6-1f7e8d9c4b2a,001"`
- `"c144543e-66d3-468f-9639-37ec74309ff0,0044"`
- `"e6f9c2d5-8a3b-4e1f-b7c9-2d5a8c1e4f7b,*99"`

## 🔧 Installation

1.	Copy the attached script to the CUCM LUA repository.
Device – Device Settings - SIP Normalization Scripts

2.	Go to the Trunk, where the MT incoming calls are terminated (from the MT LGWs)
Device – Trunk
On the bottom of the Trunk Configuration page, set the LUA and the Parameters

3. **Apply Configuration:**
   - Save and apply the trunk configuration
   - Reset the SIP trunk

## 📖 How It Works

### Display Name Modification

The script automatically modifies the following SIP headers when `prefixDisplayNameValue` is configured:

- `From`
- `Remote-Party-ID`
- `P-Preferred-Identity`
- `P-Asserted-Identity`

**Example Transformation:**
```
Original: From: "John Doe" <sip:john@example.com>
Modified: From: "MT_EMEA_Default:John Doe" <sip:john@example.com>
```

### Location-Based Number Transformation

The script processes calls based on the `X-Cisco-Location-Info` header:

#### Scenario 1: Specific Location Mapping
```
X-Cisco-Location-Info: "a8f4e2c1-92d7-4b5e-a3c6-1f7e8d9c4b2a"
LocationPrefixMap1: "a8f4e2c1-92d7-4b5e-a3c6-1f7e8d9c4b2a,*999"
Original RURI: sip:+441234567890@domain.com
Result: sip:*9991234567890@domain.com
```

#### Scenario 2: Fallback to Default
```
X-Cisco-Location-Info: "9f8e7d6c-5b4a-3928-1756-4e3d2c1b0a99"
LocationPrefixDefault: "*99"
Original RURI: sip:+441234567890@domain.com
Result: sip:*991234567890@domain.com
```

#### Scenario 3: No Location Header
```
(No X-Cisco-Location-Info header)
Result: No number transformation applied
```

## 🔍 Decision Matrix

| Condition | X-Cisco-Location-Info | Location Mapping | LocationPrefixDefault | Action |
|-----------|----------------------|------------------|----------------------|---------|
| 1 | ✅ Present | ✅ Found | N/A | Use specific mapping |
| 2 | ✅ Present | ❌ Not Found | ✅ Configured | Use default prefix |
| 3 | ✅ Present | ❌ Not Found | ❌ Empty | No transformation |
| 4 | ❌ Not Present | N/A | N/A | No transformation |

## 📝 Logging and Debugging

The script provides comprehensive logging for troubleshooting:

```lua
-- Parameter logging
trace.format("prefixDisplayNameValue: %s", displayNamePrefix)
trace.format("LocationPrefixDefault: %s", locationPrefixDefault)

-- Location mapping logging
trace.format("Loaded LocationPrefixMap1: c144543e-66d3-468f-9639-37ec74309ff0 -> 0044")
trace.format("Total location mappings loaded: 3")

-- Call processing logging
trace.format("X-Cisco-Location-Info header found: c144543e-66d3-468f-9639-37ec74309ff0")
trace.format("Location ID matches configured mapping. Using prefix: 0044")
trace.format("New Request URI set to: sip:00441234567890@domain.com")
```

## 🛠️ Configuration Examples

### Basic Configuration
```
prefixDisplayNameValue: "Company:"
LocationPrefixMap1: "a8f4e2c1-92d7-4b5e-a3c6-1f7e8d9c4b2a,*98*"
LocationPrefixDefault: "*99"
```

### Multi-Location Configuration
```
prefixDisplayNameValue: "EMEA_Branch:"
LocationPrefixMap1: "c144543e-66d3-468f-9639-37ec74309ff0,*91"
LocationPrefixMap2: "f7b2d8e4-3a1c-4f9e-b5d7-9e2c8f4a6b1d,*92"
LocationPrefixMap3: "d9e5c3a7-4f2b-4e8c-a1d6-7b9e3c5f2a8d,*93"
LocationPrefixMap4: "b3c7f1e9-5d2a-4c8f-9e1b-6a4d7c9e2f5b,*94"
LocationPrefixMap5: "e6f9c2d5-8a3b-4e1f-b7c9-2d5a8c1e4f7b,*95"
LocationPrefixDefault: "*99"
```

## 🚨 Troubleshooting

### Common Issues

1. **Parameters Not Loading:**
   - Verify parameter names match exactly (case-sensitive)
   - Check for trailing spaces in parameter values

2. **Location Mapping Not Working:**
   - Verify Location ID format in X-Cisco-Location-Info header
   - Check mapping format: "LocationID,Prefix"

3. **Display Name Not Modified:**
   - Ensure `prefixDisplayNameValue` is not empty
   - Check if headers contain display names

### Debug Steps

1. **Enable Detailed Logging:**
   ```lua
   trace.enable()
   ```

2. **Check Parameter Values:**
   - Review trace logs for parameter loading
   - Verify all expected mappings are loaded

3. **Monitor Call Flow:**
   - Check X-Cisco-Location-Info header presence
   - Verify location ID extraction
   - Monitor prefix application

## ⚠️ Disclaimer

**This script is provided as-is without any guarantee or official support from Cisco Systems. Use at your own risk in production environments. Always test thoroughly in a lab environment before deployment.**

## 👤 Author

**Georgi Dimitrov**
geodimit

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For support and questions:
- Review the troubleshooting section
- Check CUCM trace logs
- Verify script parameter configuration

## 🔄 Version History

- **v0.2** - Added LocationPrefixDefault fallback mechanism
- **v0.1** - Initial release with basic location mapping

---

**Note:** This script is designed for CUCM environments and requires proper SIP trunk configuration for optimal functionality.
