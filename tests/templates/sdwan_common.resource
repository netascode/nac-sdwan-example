*** Settings ***
Library   pabot.PabotLib
Library   RequestsLibrary
Library   JSONLibrary
Library   Collections
Library   OperatingSystem
Library   String
Library   packaging.version
Library   myutils.py

*** Variables ***
&{login_json}=   j_username=%{SDWAN_USERNAME}   j_password=%{SDWAN_PASSWORD}
&{headers}=   content-type=application/x-www-form-urlencoded

*** Keywords ***
Get SDWAN Manager Token
   Create Session   login   %{SDWAN_URL}   verify=${False}   disable_warnings=1   headers=${headers}
   ${log_level}=   Set Log Level   NONE
   ${response}=   Wait Until Keyword Succeeds   6x   10s   POST On Session   login   /j_security_check   data=${login_json}
   Set Log Level   ${log_level}
   ${r_token}=   Wait Until Keyword Succeeds   6x   10s   GET On Session   login   /dataservice/client/token
   ${cookie}=   Get from dictionary   ${response.headers}   set-cookie
   ${r_cookie}=   Split string   ${cookie}   separator=;
   Set Parallel Value For Key   manager_token   ${r_token.text}
   Set Parallel Value For Key   manager_cookie   ${r_cookie[0]}

Get SDWAN Manager Version
   ${response}=   Wait Until Keyword Succeeds   6x   10s   GET On Session   sdwan_manager   /dataservice/system/device/controllers   params=model=vmanage
   ${r_version}=   Get Value From Json   ${response.json()}   $.data[0].version
   Set Parallel Value For Key   manager_version   ${r_version[0]}

Login SDWAN Manager
   Run Only Once   Get SDWAN Manager Token
   ${manager_token}=   Get Parallel Value For Key   manager_token
   ${manager_cookie}=   Get Parallel Value For Key   manager_cookie
   ${m_headers}=   Create Dictionary   X-XSRF-TOKEN=${manager_token}   Cookie=${manager_cookie}   accept=application/json
   Create Session   sdwan_manager   %{SDWAN_URL}   headers=${m_headers}
   Run Only Once   Get SDWAN Manager Version

Logout SDWAN Manager
   ${manager_cookie}=   Get Parallel Value For Key   manager_cookie
   ${m_headers}=   Create Dictionary   Cookie=${manager_cookie}   accept=*/*
   ${manager_version}=   Get Parallel Value For Key   manager_version
   ${version_check}=   Evaluate   packaging.version.Version('${manager_version}') >= packaging.version.Version('20.12')
   IF   ${version_check}
       ${response}=   Wait Until Keyword Succeeds   6x   10s   POST On Session   sdwan_manager   /logout   headers=${m_headers}
   ELSE
       ${response}=   Wait Until Keyword Succeeds   6x   10s   GET On Session   sdwan_manager   /logout   headers=${m_headers}
   END

Should Be Equal Value Json String
   [Arguments]   ${json}    ${json_path}   ${value}=${EMPTY}  ${msg}=${EMPTY}
   ${r_value}=   Get Value From Json   ${json}   ${json_path}
   ${r_value}=   Set Variable If    ${r_value} == [] or ${r_value} == [None]    not_defined    ${r_value[0]}
   Should Be Equal As Strings    ${r_value}    ${value}    values=False    msg=${msg} expected: '${value}' and got: '${r_value}'  

Should Be Equal Value Json List
   [Arguments]   ${json}   ${json_path}   ${value}=${None}   ${msg}=${EMPTY}
   ${r_value}=   Get Value From Json   ${json}   ${json_path}
   Lists Should Be Equal   ${r_value}   ${value}   ignore_order=True    values=False    msg=${msg} expected: '${value}' and got: '${r_value}'    

Should Be Equal Value Json List Length
   [Arguments]   ${json}   ${json_path}   ${value}=${None}   ${msg}=${EMPTY}
   ${r_value}=   Get Value From Json   ${json}   ${json_path}
   ${status}=    Run Keyword And Return Status  Get Length   ${r_value[0]}
   IF  ${status} == ${True}
       ${r_length}=    Get Length     ${r_value[0]}
   ELSE
       ${r_length}=    Get Length     ${r_value}
   END
   Should Be Equal As Integers    ${r_length}    ${value}  values=False  msg=${msg} expected '${value}' items and got: '${r_length}' 

Convert String To List If Needed
   [Arguments]    ${value}
   ${is_list_string}=    Run Keyword And Return Status    Should Match Regexp    ${value}    ^\\[.*\\]$
   IF    $is_list_string and not isinstance($value, list)
      # Convert input value string to list
      ${value}=    Evaluate    json.loads(r'''${value}'''.replace("'", '"'))    modules=json
   END
   RETURN    ${value}

Extract Json List Value
   [Arguments]    ${json}    ${json_path}
   # Extract value from JSON
   ${json_value}=    Get Value From Json    ${json}    ${json_path}.vipValue
   IF    isinstance($json_value[0], list)
      ${json_list}=    Set Variable If    ${json_value} == []    not_defined    ${json_value[0]}
   ELSE
      # Extract JSON comma-separated string and parse to list
      ${json_string}=    Get Value From Json    ${json}    ${json_path}.vipValue
      ${json_list}=    Split String    ${json_string[0]}    separator=,
      ${json_list}=    Set Variable If    ${json_list} == []    not_defined    ${json_list}
   END
   RETURN    ${json_list}

Extract Json String Value
   [Arguments]    ${json}    ${json_path}
   # Extract value from JSON
   ${json_value}=    Get Value From Json    ${json}    ${json_path}.vipValue
   # If its list with one element and data model is using string, extract this element from json list to string
   IF    isinstance($json_value, list) and len($json_value) == 1 and isinstance($json_value[0], list)
      ${json_value}=    Set Variable    ${json_value[0][0]}
   ELSE
      ${json_value}=    Set Variable If    ${json_value} == []    not_defined    ${json_value[0]}
   END
   RETURN    ${json_value}

Should Be Equal Value Json Yaml UX1
   [Arguments]    ${json}    ${json_path}    ${value}    ${var_value}    ${msg}
   ${vip_type}=    Get Value From Json    ${json}    ${json_path}.vipType
   IF    $vip_type == ['constant']
      # Verify global value
      ${value}=    Convert String To List If Needed    ${value}
      IF    isinstance($value, list)
         # Verify list value
         ${json_list}=    Extract Json List Value    ${json}    ${json_path}
         Lists Should Be Equal    ${json_list}    ${value}    ignore_order=True    values=False    msg=${msg} expected: '${value}' and got: '${json_list}'
      ELSE
         # Verify non-list value (int, str, bool)
         IF    $value in ["True", "False"]
            # Bool values represented by string needs to be converted to lowercase
            ${value}=    Set Variable    ${value.lower()}
         END
         # Extract value from JSON
         ${json_value}=    Extract Json String Value    ${json}    ${json_path}
         Should Be Equal As Strings    ${json_value}    ${value}    values=False    msg=${msg} expected: '${value}' and got: '${json_value}'  
      END
   ELSE IF    $vip_type == ['variableName']
      # Verify variable value
      Should Be Equal Value Json String    ${json}    ${json_path}.vipVariableName    ${var_value}    msg=${msg}_variable
   ELSE
      # Verify default/ignore value
      Should Be Equal As Strings    not_defined    ${value}    msg=${msg} expected: '${value}' and got: 'not_defined'
   END

Should Be Equal Value Json Yaml
    [Arguments]    ${json}    ${json_path}    ${value}    ${var_value}    ${msg}    ${var_msg}
    ${opt_type}=    Get Value From Json    ${json}    ${json_path}.optionType
    IF    ${opt_type} == ['global']
        ${type_check}=    Evaluate    type($value).__name__
        IF    '${type_check}' == 'list'
            ${dt_list}=    Get Value From Json    ${json}    ${json_path}.value
            ${r_dt_list}=    Evaluate    [str(element) for element in ${dt_list}[0]]
            Lists Should Be Equal    ${r_dt_list}    ${value}    ignore_order=True    values=False    msg=${msg} expected: '${value}' and got: '${r_dt_list}'
        ELSE
            Should Be Equal Value Json String    ${json}    ${json_path}.value    ${value}    msg=${msg}
        END 
    ELSE IF    ${opt_type} == ['variable']
        ${r_value}=    Get Value From Json    ${json}    ${json_path}.value
        ${r_value}=    Evaluate    '${r_value[0]}'.replace("{", "").replace("}", "")
        Should Be Equal As Strings    ${var_value}    ${r_value}    values=False    msg=${var_msg} expected: '${var_value}' and got: '${r_value}'
    ELSE
        Should Be Equal As Strings    not_defined    ${value}    values=False    msg=${msg} expected: '${value}' and got: 'not_defined'    
        Should Be Equal As Strings    not_defined    ${var_value}    values=False    msg=${var_msg} expected: '${var_value}' and got: 'not_defined'
    END

# This keyword is same as "Should Be Equal Value Json String" but it normalizes the special characters and spaces for robot evaluation
Should Be Equal Value Json Special_String
   [Arguments]   ${json}    ${json_path}   ${value}=${EMPTY}  ${msg}=${EMPTY}
   ${r_value}=   Get Value From Json   ${json}   ${json_path}
   TRY
      ${r_value}=   Set Variable If    ${r_value} == [] or ${r_value} == ['']    not_defined    ${r_value}[0]
   EXCEPT
      ${r_value}=   Set Variable    not_defined
   END
   ${r_value}=   normalize escapes spaces    text=${r_value}
   ${value}=   normalize escapes spaces    text=${value}
   Should Be Equal As Strings    ${r_value}    ${value}    msg=${msg} expected: '${value}' and got: '${r_value}'
