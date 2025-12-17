*** Settings ***
Documentation   Verify AAA Feature Template
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process    Logout SDWAN Manager
Default Tags    sdwan    config    feature_templates
Resource        ../../sdwan_common.resource

{% if sdwan.edge_feature_templates is defined and sdwan.edge_feature_templates.aaa_templates is defined %}

*** Test Cases ***
Get AAA Feature Templates
    ${r}=    GET On Session    sdwan_manager    /dataservice/template/feature
    ${r}=    Get Value From Json    ${r.json()}    $..data[?(@..templateType=="cedge_aaa")]
    Set Suite Variable    ${r}

{% for ft_yaml in sdwan.edge_feature_templates.aaa_templates | default([]) %}

Verify Edge Feature Template AAA Feature Template {{ ft_yaml.name }}
    ${ft_summary_json}=    Get Value From Json    ${r}    $[?(@.templateName=="{{ ft_yaml.name }}")]
    Should Not be Empty   ${ft_summary_json}   msg=Feature Template '{{ft_yaml.name}}' should be present on the Manager
    Should Be Equal Value Json String    ${ft_summary_json}    $..templateName    {{ ft_yaml.name }}    msg=name
    Should Be Equal Value Json Special_String    ${ft_summary_json}    $..templateDescription    {{ ft_yaml.description | normalize_special_string }}    msg=description

    # Device types validation
    {% set device_types_yaml = [] %}
    {% for item in ft_yaml.device_types | default(defaults.sdwan.edge_feature_templates.aaa_templates.device_types) %}
    {% set device_type = "vedge-" ~ item %}
    {% set _ = device_types_yaml.append(device_type) %}
    {% endfor %}
    ${device_types_json}=    Get Value From Json    ${ft_summary_json}    $..deviceType
    ${device_types_yaml}=    Create List           {{ device_types_yaml | join('   ') }}
    Lists Should Be Equal    ${device_types_json}[0]    ${device_types_yaml}    ignore_order=True    msg=device_types

    # Get template definition
    ${ft_id}=    Get Value From Json    ${r}    $[?(@.templateName=="{{ ft_yaml.name }}")].templateId
    ${ft}=    GET On Session    sdwan_manager    /dataservice/template/feature/definition/${ft_id[0]}

    Should Be Equal Value Json List Length    ${ft.json()}    $..["accounting-rule"].vipValue    {{ ft_yaml.accounting_rules | default([]) | length }}    msg=accounting_rules length

{% for accounting_rule in ft_yaml.accounting_rules | default([]) %}

    Log    === Accounting Rule {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["accounting-rule"].vipValue[{{loop.index0}}].method
    ...    {{ accounting_rule.method | default("not_defined")}}
    ...    {{ accounting_rule.method_variable | default("not_defined") }}
    ...    msg=accounting_rules.method

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["accounting-rule"].vipValue[{{loop.index0}}].level
    ...    {{ accounting_rule.privilege_level | default("not_defined")}}
    ...    {{ accounting_rule.privilege_level_variable | default("not_defined") }}
    ...    msg=accounting_rules.privilege_level

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["accounting-rule"].vipValue[{{loop.index0}}].["start-stop"]
    ...    {{ accounting_rule.start_stop | default("not_defined") | lower }}
    ...    {{ accounting_rule.start_stop_variable | default("not_defined")}}
    ...    msg=accounting_rules.start_stop

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["accounting-rule"].vipValue[{{loop.index0}}].group
    ...    {{ accounting_rule.groups | default("not_defined") }}
    ...    {{ accounting_rule.groups_variable | default("not_defined") }}
    ...    msg=accounting_rules.groups

{% endfor %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["server-auth-order"]
    ...    {{ ft_yaml.authentication_and_authorization_order | default("not_defined") }}
    ...    {{ ft_yaml.authentication_and_authorization_order_variable | default("not_defined") }}
    ...    msg=authentication_and_authorization_order_variable

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["authorization-config-commands"]
    ...    {{ ft_yaml.authorization_config_commands | default("not_defined") | lower }}
    ...    {{ ft_yaml.authorization_config_commands_variable | default("not_defined") }}
    ...    msg=authorization_config_commands

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["authorization-console"]
    ...    {{ ft_yaml.authorization_console | default("not_defined") | lower }}
    ...    {{ ft_yaml.authorization_console_variable | default("not_defined") }}
    ...    msg=authorization_console

    Should Be Equal Value Json List Length    ${ft.json()}    $..["authorization-rule"].vipValue    {{ ft_yaml.authorization_rules | default([]) | length }}    msg=authorization_rules length

{% for authorization_rule in ft_yaml.authorization_rules | default([]) %}

    Log    === Authorization Rule {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["authorization-rule"].vipValue[{{loop.index0}}].method
    ...    {{ authorization_rule.method | default("not_defined") }}
    ...    {{ authorization_rule.method_variable | default("not_defined") }}
    ...    msg=authorization_rules.method

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["authorization-rule"].vipValue[{{loop.index0}}].level
    ...    {{ authorization_rule.privilege_level | default("not_defined") }}
    ...    {{ authorization_rule.privilege_level_variable | default("not_defined") }}
    ...    msg=authorization_rules.privilege_level

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["authorization-rule"].vipValue[{{loop.index0}}].["if-authenticated"]
    ...    {{ authorization_rule.authenticated | lower | default("not_defined")}}
    ...    {{ authorization_rule.authenticated_variable | default("not_defined") }}
    ...    msg=authorization_rules.authenticated

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["authorization-rule"].vipValue[{{loop.index0}}].group
    ...    {{ authorization_rule.groups | default("not_defined") }}
    ...    {{ authorization_rule.groups_variable | default("not_defined") }}
    ...    msg=authorization_rules.groups

{% endfor %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..authentication.dot1x.default.authentication_group
    ...    {{ ft_yaml.dot1x_authentication | default("not_defined") | lower }}
    ...    {{ ft_yaml.dot1x_authentication_variable | default("not_defined") }}
    ...    msg=dot1x_authentication

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..accounting.dot1x.default.["start-stop"].accounting_group
    ...    {{ ft_yaml.dot1x_accounting | default("not_defined") | lower }}
    ...    {{ ft_yaml.dot1x_accounting_variable | default("not_defined") }}
    ...    msg=dot1x_accounting

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["radius-dynamic-author"]["domain-stripping"]
    ...    {{ (ft_yaml.radius_dynamic_author | default({})).domain_stripping | default("not_defined") }}
    ...    {{ (ft_yaml.radius_dynamic_author | default({})).domain_stripping_variable | default("not_defined") }}
    ...    msg=radius_dynamic_author.domain_stripping

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["radius-dynamic-author"]["auth-type"]
    ...    {{ (ft_yaml.radius_dynamic_author | default({})).authentication_type | default("not_defined") }}
    ...    {{ (ft_yaml.radius_dynamic_author | default({})).authentication_type_variable | default("not_defined") }}
    ...    msg=radius_dynamic_author.authentication_type

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["radius-dynamic-author"].port
    ...    {{ (ft_yaml.radius_dynamic_author | default({})).port | default("not_defined") }}
    ...    {{ (ft_yaml.radius_dynamic_author | default({})).port_variable | default("not_defined") }}
    ...    msg=radius_dynamic_author.port

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["radius-dynamic-author"]["rda-server-key"]
    ...    {{ (ft_yaml.radius_dynamic_author | default({})).server_key | default("not_defined") }}
    ...    {{ (ft_yaml.radius_dynamic_author | default({})).server_key_variable | default("not_defined") }}
    ...    msg=radius_dynamic_author.server_key

    Should Be Equal Value Json List Length    ${ft.json()}    $..["radius-dynamic-author"]["radius-client"].vipValue    {{ ft_yaml.radius_dynamic_author.clients | default([]) | length }}    msg=radius_dynamic_author.clients length

{% for radius_client in ft_yaml.radius_dynamic_author.clients | default([]) %}

    Log    === RADIUS Dynamic Author Client {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["radius-dynamic-author"]["radius-client"].vipValue[{{loop.index0}}].ip
    ...    {{ radius_client.ip | default("not_defined") }}
    ...    {{ radius_client.ip_variable | default("not_defined") }}
    ...    msg=radius_dynamic_author.clients.ip

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["radius-dynamic-author"]["radius-client"].vipValue[{{loop.index0}}].vpn.vipValue..name
    ...    {{ radius_client.vpn_id | default("not_defined") }}
    ...    {{ radius_client.vpn_id_variable | default("not_defined") }}
    ...    msg=radius_dynamic_author.clients.vpn_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["radius-dynamic-author"]["radius-client"].vipValue[{{loop.index0}}].vpn.vipValue..server-key
    ...    {{ radius_client.server_key | default("not_defined") }}
    ...    {{ radius_client.server_key_variable | default("not_defined") }}
    ...    msg=radius_dynamic_author.clients.server_key

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    $..radius.vipValue    {{ ft_yaml.radius_server_groups | default([]) | length }}    msg=radius_server_groups length

{% for radius_index in range(ft_yaml.radius_server_groups | default([]) | length()) %}

    Log    === RADIUS Server Group {{radius_index}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..radius.vipValue[{{ radius_index }}]["group-name"]
    ...    {{ ft_yaml.radius_server_groups[radius_index].name | default("not_defined") }}
    ...    {{ ft_yaml.radius_server_groups[radius_index].name_variable | default("not_defined") }}
    ...    msg=radius_server_groups.name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..radius.vipValue[{{ radius_index }}]["source-interface"]
    ...    {{ ft_yaml.radius_server_groups[radius_index].source_interface | default("not_defined") }}
    ...    {{ ft_yaml.radius_server_groups[radius_index].source_interface_variable | default("not_defined") }}
    ...    msg=radius_server_groups.source_interface

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..radius.vipValue[{{ radius_index }}].vpn
    ...    {{ ft_yaml.radius_server_groups[radius_index].vpn_id | default("not_defined") }}
    ...    {{ ft_yaml.radius_server_groups[radius_index].vpn_id_variable | default("not_defined") }}
    ...    msg=radius_server_groups.vpn_id

    Should Be Equal Value Json List Length    ${ft.json()}    $..radius.vipValue[{{ radius_index }}].server.vipValue    {{ ft_yaml.radius_server_groups[radius_index].servers | length }}    msg=radius_server_groups.servers length

{% for server_index in range(ft_yaml.radius_server_groups[radius_index].servers | default([]) | length()) %}

    Log    === RADIUS Server Group {{radius_index}} Server {{server_index}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..radius.vipValue[{{ radius_index }}].server.vipValue[{{ server_index }}].address
    ...    {{ ft_yaml.radius_server_groups[radius_index].servers[server_index].address | default("not_defined") }}
    ...    {{ ft_yaml.radius_server_groups[radius_index].servers[server_index].address_variable | default("not_defined") }}
    ...    msg=radius_server_groups.servers.address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..radius.vipValue[{{ radius_index }}].server.vipValue[{{ server_index }}]["auth-port"]
    ...    {{ ft_yaml.radius_server_groups[radius_index].servers[server_index].authentication_port | default("not_defined") }}
    ...    {{ ft_yaml.radius_server_groups[radius_index].servers[server_index].authentication_port_variable | default("not_defined") }}
    ...    msg=radius_server_groups.servers.authentication_port

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..radius.vipValue[{{ radius_index }}].server.vipValue[{{ server_index }}]["acct-port"]
    ...    {{ ft_yaml.radius_server_groups[radius_index].servers[server_index].accounting_port | default("not_defined") }}
    ...    {{ ft_yaml.radius_server_groups[radius_index].servers[server_index].accounting_port_variable | default("not_defined") }}
    ...    msg=radius_server_groups.servers.accounting_port

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..radius.vipValue[{{ radius_index }}].server.vipValue[{{ server_index }}].timeout
    ...    {{ ft_yaml.radius_server_groups[radius_index].servers[server_index].timeout | default("not_defined") }}
    ...    {{ ft_yaml.radius_server_groups[radius_index].servers[server_index].timeout_variable | default("not_defined") }}
    ...    msg=radius_server_groups.servers.timeout

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..radius.vipValue[{{ radius_index }}].server.vipValue[{{ server_index }}].retransmit
    ...    {{ ft_yaml.radius_server_groups[radius_index].servers[server_index].retransmit_count | default("not_defined") }}
    ...    {{ ft_yaml.radius_server_groups[radius_index].servers[server_index].retransmit_count_variable | default("not_defined") }}
    ...    msg=radius_server_groups.servers.retransmit_count

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..radius.vipValue[{{ radius_index }}].server.vipValue[{{ server_index }}]["key-type"]
    ...    {{ ft_yaml.radius_server_groups[radius_index].servers[server_index].key_type | default("not_defined") }}
    ...    {{ ft_yaml.radius_server_groups[radius_index].servers[server_index].key_type_variable | default("not_defined") }}
    ...    msg=radius_server_groups.servers.key_type

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..radius.vipValue[{{ radius_index }}].server.vipValue[{{ server_index }}].key
    ...    {{ ft_yaml.radius_server_groups[radius_index].servers[server_index].key | default("not_defined") }}
    ...    {{ ft_yaml.radius_server_groups[radius_index].servers[server_index].key_variable | default("not_defined") }}
    ...    msg=radius_server_groups.servers.key

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..radius.vipValue[{{ radius_index }}].server.vipValue[{{ server_index }}]["secret-key"]
    ...    {{ ft_yaml.radius_server_groups[radius_index].servers[server_index].secret_key | default("not_defined") }}
    ...    {{ ft_yaml.radius_server_groups[radius_index].servers[server_index].secret_key_variable | default("not_defined") }}
    ...    msg=radius_server_groups.servers.secret_key

{% endfor %}

{% endfor %}

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["radius-trustsec"]["cts-auth-list"]
    ...    {{ (ft_yaml.radius_trustsec | default({})).cts_authorization_list | default("not_defined") }}
    ...    {{ (ft_yaml.radius_trustsec | default({})).cts_authorization_list_variable | default("not_defined") }}
    ...    msg=radius_trustsec.cts_authorization_list

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..["radius-trustsec"]["radius-trustsec-group"]
    ...    {{ (ft_yaml.radius_trustsec | default({})).server_group | default("not_defined") }}
    ...    {{ (ft_yaml.radius_trustsec | default({})).server_group_variable | default("not_defined") }}
    ...    msg=radius_trustsec.server_group

    Should Be Equal Value Json List Length    ${ft.json()}    $..tacacs.vipValue    {{ ft_yaml.tacacs_server_groups | default([]) | length }}    msg=tacacs_server_groups length

{% for tacacs_index in range(ft_yaml.tacacs_server_groups | default([]) | length()) %}

    Log    === TACACS Server Group {{tacacs_index}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..tacacs.vipValue[{{ tacacs_index }}]["group-name"]
    ...    {{ ft_yaml.tacacs_server_groups[tacacs_index].name | default("not_defined") }}
    ...    {{ ft_yaml.tacacs_server_groups[tacacs_index].name_variable | default("not_defined") }}
    ...    msg=tacacs_server_groups.name

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..tacacs.vipValue[{{ tacacs_index }}].vpn
    ...    {{ ft_yaml.tacacs_server_groups[tacacs_index].vpn_id | default("not_defined") }}
    ...    {{ ft_yaml.tacacs_server_groups[tacacs_index].vpn_id_variable | default("not_defined") }}
    ...    msg=tacacs_server_groups.vpn_id

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..tacacs.vipValue[{{ tacacs_index }}]["source-interface"]
    ...    {{ ft_yaml.tacacs_server_groups[tacacs_index].source_interface | default("not_defined") }}
    ...    {{ ft_yaml.tacacs_server_groups[tacacs_index].source_interface_variable | default("not_defined") }}
    ...    msg=tacacs_server_groups.source_interface

    Should Be Equal Value Json List Length    ${ft.json()}    $..tacacs.vipValue[{{ tacacs_index }}].server.vipValue    {{ ft_yaml.tacacs_server_groups[tacacs_index].servers | length }}    msg=tacacs_server_groups.servers length

{% for server_index in range(ft_yaml.tacacs_server_groups[tacacs_index].servers | default([]) | length()) %}

    Log    === TACACS Server Group {{tacacs_index}} Server {{server_index}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..tacacs.vipValue[{{ tacacs_index }}].server.vipValue[{{ server_index }}].address
    ...    {{ ft_yaml.tacacs_server_groups[tacacs_index].servers[server_index].address | default("not_defined") }}
    ...    {{ ft_yaml.tacacs_server_groups[tacacs_index].servers[server_index].address_variable | default("not_defined") }}
    ...    msg=tacacs_server_groups.servers.address

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..tacacs.vipValue[{{ tacacs_index }}].server.vipValue[{{ server_index }}].port
    ...    {{ ft_yaml.tacacs_server_groups[tacacs_index].servers[server_index].port | default("not_defined") }}
    ...    {{ ft_yaml.tacacs_server_groups[tacacs_index].servers[server_index].port_variable | default("not_defined") }}
    ...    msg=tacacs_server_groups.servers.port

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..tacacs.vipValue[{{ tacacs_index }}].server.vipValue[{{ server_index }}].timeout
    ...    {{ ft_yaml.tacacs_server_groups[tacacs_index].servers[server_index].timeout | default("not_defined") }}
    ...    {{ ft_yaml.tacacs_server_groups[tacacs_index].servers[server_index].timeout_variable | default("not_defined") }}
    ...    msg=tacacs_server_groups.servers.timeout

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..tacacs.vipValue[{{ tacacs_index }}].server.vipValue[{{ server_index }}].key
    ...    {{ ft_yaml.tacacs_server_groups[tacacs_index].servers[server_index].key | default("not_defined") }}
    ...    {{ ft_yaml.tacacs_server_groups[tacacs_index].servers[server_index].key_variable | default("not_defined") }}
    ...    msg=tacacs_server_groups.servers.key

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..tacacs.vipValue[{{ tacacs_index }}].server.vipValue[{{ server_index }}]["secret-key"]
    ...    {{ ft_yaml.tacacs_server_groups[tacacs_index].servers[server_index].secret_key | default("not_defined") }}
    ...    {{ ft_yaml.tacacs_server_groups[tacacs_index].servers[server_index].secret_key_variable | default("not_defined") }}
    ...    msg=tacacs_server_groups.servers.secret_key

{% endfor %}

{% endfor %}

    Should Be Equal Value Json List Length    ${ft.json()}    $..user.vipValue    {{ ft_yaml.users | default([]) | length }}    msg=users length

{% for user in ft_yaml.users | default([]) %}

    Log    === User {{loop.index0}} ===
    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..user.vipValue[{{loop.index0}}].name
    ...    {{ user.name | default("not_defined") }}
    ...    {{ user.name_variable | default("not_defined") }}
    ...    msg=users.name

    Should Be Equal Value Json String    ${ft.json()}    $..user.vipValue[{{loop.index0}}].vipOptional
    ...    {{ user.optional | default("not_defined") }}
    ...    msg=users.optional

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..user.vipValue[{{loop.index0}}].password
    ...    {{ user.password | default("not_defined") }}
    ...    {{ user.password_variable | default("not_defined") }}
    ...    msg=users.password

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..user.vipValue[{{loop.index0}}].privilege
    ...    {{ user.privilege_level | default("not_defined") }}
    ...    {{ user.privilege_level_variable | default("not_defined") }}
    ...    msg=users.privilege_level

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..user.vipValue[{{loop.index0}}].secret
    ...    {{ user.secret | default("not_defined") }}
    ...    {{ user.secret_variable | default("not_defined") }}
    ...    msg=users.secret

    Should Be Equal Value Json Yaml UX1    ${ft.json()}    $..user.vipValue[{{loop.index0}}]["pubkey-chain"]..["key-string"]
    ...    {{ user.ssh_rsa_keys | default("not_defined") }}
    ...    {{ user.ssh_rsa_keys_variable | default("not_defined") }}
    ...    msg=users.ssh_rsa_keys

{% endfor %}

{% endfor %}

{% endif %}
