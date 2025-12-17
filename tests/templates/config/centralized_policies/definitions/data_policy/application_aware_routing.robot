*** Settings ***
Documentation   Verify Application Aware Routing
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process   Logout SDWAN Manager
Default Tags    sdwan    config    centralized_policies    data_policies
Resource        ../../../../sdwan_common.resource

{% if sdwan.centralized_policies.definitions.data_policy.application_aware_routing is defined %}

*** Test Cases ***
Get Application Aware Routing
    ${r}=    GET On Session    sdwan_manager    /dataservice/template/policy/definition/approute
    Set Suite Variable    ${r}

{% for aar in sdwan.centralized_policies.definitions.data_policy.application_aware_routing | default([]) %}

Verify Centralized Policies Data Policy Application Aware Routing {{ aar.name }}
    ${aar_id}=   Get Value From Json   ${r.json()}   $..data[?(@..name=="{{ aar.name }}")].definitionId
    ${r_id}=   GET On Session   sdwan_manager   /dataservice/template/policy/definition/approute/${aar_id[0]}
    Set Suite Variable    ${r_id}
    Should Be Equal Value Json String    ${r_id.json()}    $..name    {{ aar.name }}    msg=name
    Should Be Equal Value Json Special_String    ${r_id.json()}    $..description    {{ aar.description | normalize_special_string }}    msg=description

    ${default_action_ref_id}=    Get Value From Json    ${r_id.json()}    $..defaultAction.ref
    IF    ${default_action_ref_id} == []
        Should Be Equal Value Json String    ${r_id.json()}    $..defaultAction.ref    {{ aar.default_action_sla_class_list | default("not_defined") }}    msg=default action sla class list
    ELSE
        ${default_sla_class_match}=   GET On Session   sdwan_manager   /dataservice/template/policy/list/sla/${default_action_ref_id[0]}
        Should Be Equal Value Json String    ${default_sla_class_match.json()}    $..name    {{ aar.default_action_sla_class_list | default("not_defined") }}    msg=default action sla class list
    END

    ${sequence_items}=    Get Value From Json    ${r_id.json()}    $.sequences
    ${sequence_length}=    Get Length    ${sequence_items[0]}
    Should Be Equal As Integers    ${sequence_length}    {{ aar.sequences | default([]) | length }}    msg=sequences

{% for sequence in aar.sequences | default([]) %}

    Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}].sequenceId    {{ sequence.id }}    msg=sequence id
    Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}].sequenceName    {{ sequence.name }}    msg=sequence name

{% set type = ({"app_route":"appRoute"}) %}
    Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}].sequenceType    {{ type[(sequence.type | default(defaults.sdwan.centralized_policies.definitions.data_policy.application_aware_routing.sequences.type))] }}    msg=sequence type

    Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}].sequenceIpType   {{ sequence.ip_type | default((defaults.sdwan.centralized_policies.definitions.data_policy.application_aware_routing.sequences.ip_type) if defaults is defined else "not_defined") }}    msg=sequence ip type

    ${application_list_ref_id}=    Get Value From Json    ${r_id.json()}    $..sequences[{{loop.index0}}].match.entries[?(@.field=="appList")].ref
    IF    ${application_list_ref_id} == []
        Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}].match.entries[?(@.field=="appList")].ref    {{ sequence.match_criterias.application_list | default("not_defined") }}    msg=application list
    ELSE
        ${application_list_match_id}=   GET On Session   sdwan_manager   /dataservice/template/policy/list/app/${application_list_ref_id[0]}
        Should Be Equal Value Json String    ${application_list_match_id.json()}    $..name    {{ sequence.match_criterias.application_list | default("not_defined") }}    msg=application list
    END

    ${dns_application_list_ref_id}=    Get Value From Json    ${r_id.json()}    $..sequences[{{loop.index0}}].match.entries[?(@.field=="dnsAppList")].ref
    IF    ${dns_application_list_ref_id} == []
        Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}].match.entries[?(@.field=="dnsAppList")].ref    {{ sequence.match_criterias.dns_application_list | default("not_defined") }}    msg=dns application list
    ELSE
        ${dns_application_list_match_id}=   GET On Session   sdwan_manager   /dataservice/template/policy/list/app/${dns_application_list_ref_id[0]}
        Should Be Equal Value Json String    ${dns_application_list_match_id.json()}    $..name    {{ sequence.match_criterias.dns_application_list | default("not_defined") }}    msg=dns application list
    END

    Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}].match.entries[?(@.field=="dns")].value    {{ sequence.match_criterias.dns | default("not_defined") }}    msg=dns
    Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}].match.entries[?(@.field=="dscp")].value    {{ sequence.match_criterias.dscp | default("not_defined") }}    msg=dscp
    Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}].match.entries[?(@.field=="plp")].value    {{ sequence.match_criterias.plp | default("not_defined") }}    msg=plp

{% if sequence.match_criterias.protocols | default("not_defined") == 'not_defined' %}
    Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}].match.entries[?(@.field=="protocol")].value    {{ sequence.match_criterias.protocols | default("not_defined") }}    msg=no protocols defined
{% else %}
    ${protocols_list}=    Create List    {{ sequence.match_criterias.protocols | default([]) | join('   ') }}
    ${proto}=    Get Value From Json    ${r_id.json()}    $..sequences[{{loop.index0}}].match.entries[?(@.field=="protocol")].value
    ${rec_proto_list}=    Split String    ${proto[0]}
    Lists Should Be Equal    ${rec_proto_list}    ${protocols_list}    ignore_order=True    msg=protocols
{% endif %}

    ${source_data_prefix_list_ref_id}=    Get Value From Json    ${r_id.json()}    $..sequences[{{loop.index0}}]..match.entries[?(@.field=="sourceDataPrefixList")].ref
    IF    ${source_data_prefix_list_ref_id} == []
        Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}]..match.entries[?(@.field=="sourceDataPrefixList")].ref    {{ sequence.match_criterias.source_data_prefix_list | default("not_defined") }}    msg=source data prefix list
    ELSE
        ${source_data_prefix_list_match_id}=   GET On Session   sdwan_manager   /dataservice/template/policy/list/dataprefix/${source_data_prefix_list_ref_id[0]}
        Should Be Equal Value Json String    ${source_data_prefix_list_match_id.json()}    $..name    {{ sequence.match_criterias.source_data_prefix_list | default("not_defined") }}    msg=source data prefix list
    END

    Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}]..match.entries[?(@.field=="sourceIp")].value   {{ sequence.match_criterias.source_data_prefix | default("not_defined") }}    msg=source data prefix

{% set source_port_range_list = [] %}
{% for item in sequence.match_criterias.source_port_ranges | default([]) %}
{% set test_list = [] %}
{% set _ = test_list.append(item.from) %}
{% set _ = test_list.append(item.to) %}
{% set source_port_range_test = '-'.join(test_list | map('string')) %}
{% set _ = source_port_range_list.append(source_port_range_test) %}
{% endfor %}

{% if sequence.match_criterias.source_ports is defined and sequence.match_criterias.source_port_ranges is defined%}
{% set req_source_port = sequence.match_criterias.source_ports  %}
{% set source_string = req_source_port | map('string') | join(',') %}
{% set new_source_port_list = source_string.split(',') %}
{% set source_list = new_source_port_list + source_port_range_list %}
    ${list}=   Create List   {{ source_list | join('   ') }}
    ${r_sourceport}=    Get Value From Json    ${r_id.json()}    $..sequences[{{loop.index0}}].match.entries[?(@..field=="sourcePort")].value
    ${sourceport_list}=    Split String    ${r_sourceport[0]}
    Lists Should Be Equal    ${sourceport_list}    ${list}    msg=source ports and ranges
{% elif sequence.match_criterias.source_ports is defined %}
    ${list}=   Create List   {{ sequence.match_criterias.source_ports | join('   ') }}
    ${r_sourceport}=    Get Value From Json    ${r_id.json()}    $..sequences[{{loop.index0}}].match.entries[?(@..field=="sourcePort")].value
    ${sourceport_list}=    Split String    ${r_sourceport[0]}
    Lists Should Be Equal    ${sourceport_list}    ${list}    msg=source ports
{% elif sequence.match_criterias.source_port_ranges is defined %}
    ${list} =   Create List   {{ source_port_range_list | join('   ') }}
    ${r_sourceport}=    Get Value From Json    ${r_id.json()}    $..sequences[{{loop.index0}}].match.entries[?(@..field=="sourcePort")].value
    ${sourceport_list}=    Split String    ${r_sourceport[0]}
    Lists Should Be Equal    ${sourceport_list}    ${list}    msg=source ports ranges
{% endif %}

    ${destination_data_prefix_list_ref_id}=    Get Value From Json    ${r_id.json()}    $..sequences[{{loop.index0}}]..match.entries[?(@.field=="destinationDataPrefixList")].ref
    IF    ${destination_data_prefix_list_ref_id} == []
        Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}]..match.entries[?(@.field=="destinationDataPrefixList")].ref    {{ sequence.match_criterias.destination_data_prefix_list | default("not_defined") }}    msg=destination data prefix list
    ELSE
        ${destination_data_prefix_list_match_id}=   GET On Session   sdwan_manager   /dataservice/template/policy/list/dataprefix/${destination_data_prefix_list_ref_id[0]}
        Should Be Equal Value Json String    ${destination_data_prefix_list_match_id.json()}    $..name    {{ sequence.match_criterias.destination_data_prefix_list | default("not_defined") }}    msg=destination data prefix list
    END

    Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}]..match.entries[?(@.field=="destinationIp")].value   {{ sequence.match_criterias.destination_data_prefix | default("not_defined") }}    msg=destination data prefix

{% set destination_port_range_list = [] %}
{% for item in sequence.match_criterias.destination_port_ranges | default([]) %}
{% set test_list = [] %}
{% set _ = test_list.append(item.from) %}
{% set _ = test_list.append(item.to) %}
{% set destination_port_range_test = '-'.join(test_list | map('string')) %}
{% set _ = destination_port_range_list.append(destination_port_range_test) %}
{% endfor %}

{% if sequence.match_criterias.destination_ports is defined and sequence.match_criterias.destination_port_ranges is defined%}
{% set req_destination_port = sequence.match_criterias.destination_ports  %}
{% set destination_string = req_destination_port | map('string') | join(',') %}
{% set new_dest_port_list = destination_string.split(',') %}
{% set destination_list = new_dest_port_list + destination_port_range_list %}
    ${list}=   Create List   {{ destination_list | join('   ') }}
    ${r_destinationport}=    Get Value From Json    ${r_id.json()}    $..sequences[{{loop.index0}}].match.entries[?(@..field=="destinationPort")].value
    ${destinationport_list}=    Split String    ${r_destinationport[0]}
    Lists Should Be Equal    ${destinationport_list}    ${list}    msg=destination ports and ranges
{% elif sequence.match_criterias.destination_ports is defined %}
    ${list}=   Create List   {{ sequence.match_criterias.destination_ports | join('   ') }}
    ${r_destinationport}=    Get Value From Json    ${r_id.json()}    $..sequences[{{loop.index0}}].match.entries[?(@..field=="destinationPort")].value
    ${destinationport_list}=    Split String    ${r_destinationport[0]}
    Lists Should Be Equal    ${destinationport_list}    ${list}    msg=destination ports
{% elif sequence.match_criterias.destination_port_ranges is defined %}
    ${list} =   Create List   {{ destination_port_range_list | join('   ') }}
    ${r_destinationport}=    Get Value From Json    ${r_id.json()}    $..sequences[{{loop.index0}}].match.entries[?(@..field=="destinationPort")].value
    ${destinationport_list}=    Split String    ${r_destinationport[0]}
    Lists Should Be Equal    ${destinationport_list}    ${list}    msg=destination ports ranges
{% endif %}

    Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}]..match.entries[?(@.field=="trafficTo")].value   {{ sequence.match_criterias.traffic_to | default("not_defined") }}    msg=traffic to
    Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}]..match.entries[?(@.field=="destinationRegion")].value   {{ sequence.match_criterias.destination_region | default("not_defined") }}    msg=destination region
    Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}].actions[?(@.type=="count")].parameter    {{ sequence.actions.counter_name | default("not_defined") }}    msg=actions counter name

{% if sequence.actions.log is defined and sequence.actions.log == True | default("not_defined") %}
    Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}].actions[?(@.type=="log")].type     log    msg=log is activated
{% elif sequence.actions.log is not defined or sequence.actions.log == False | default("not_defined") %}
    Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}].actions[?(@.type=="log")].type     not_defined    msg=log is not defined or value is false
{% endif %}

{% if sequence.actions.backup_sla_preferred_colors | default("not_defined") == 'not_defined' %}
    Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}].actions[?(@.type=="backupSlaPreferredColor")].parameter    {{ sequence.actions.backup_sla_preferred_colors | default("not_defined") }}    msg=backup sla preferred colors
{% else %}
    ${recd_colors_list}=    Get Value From Json    ${r_id.json()}    $..sequences[{{loop.index0}}].actions[?(@.type=="backupSlaPreferredColor")].parameter
    ${backupsla_colors_list}=    Split String    ${recd_colors_list[0]}
    ${backup_sla_preferred_colors}=    Create List    {{ sequence.actions.backup_sla_preferred_colors | default("not_defined") | join('   ') }}
    Lists Should Be Equal    ${backupsla_colors_list}    ${backup_sla_preferred_colors}    ignore_order=True    msg=backup sla preferred colors
{% endif %}

{% if sequence.actions.cloud_sla is defined and sequence.actions.cloud_sla == True | default("not_defined") %}
    Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}].actions[?(@.type=="cloudSaas")].type     cloudSaas    msg=cloud sla is activated
{% elif sequence.actions.cloud_sla is not defined or sequence.actions.cloud_sla == False | default("not_defined") %}
    Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}].actions[?(@.type=="cloudSaas")].type     not_defined    msg=cloud sla is not defined or value is false
{% endif %}

    ${sla_class_list_ref_id}=    Get Value From Json    ${r_id.json()}    $..sequences[{{loop.index0}}].actions[?(@.type=="slaClass")].parameter[?(@.field=="name")].ref
    IF    ${sla_class_list_ref_id} == []
        Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}].actions[?(@.type=="slaClass")].parameter[?(@.field=="name")].ref    {{ (sequence.actions | default({})).sla_class_list.sla_class_list | default("not_defined") }}    msg=sla class list
    ELSE
        ${sla_class_list_match_id}=   GET On Session   sdwan_manager   /dataservice/template/policy/list/sla/${sla_class_list_ref_id[0]}
        Should Be Equal Value Json String    ${sla_class_list_match_id.json()}    $..name    {{ (sequence.actions | default({})).sla_class_list.sla_class_list | default("not_defined") }}    msg=sla class list
    END

{% if (sequence.actions | default({})).sla_class_list.preferred_colors | default("not_defined") == 'not_defined' %}
    Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}].actions[?(@.type=="slaClass")].parameter[?(@.field=="preferredColor")].value    {{ (sequence.actions | default({})).sla_class_list.preferred_colors | default("not_defined") }}    msg=preferred colors
{% else %}
    ${colors_list}=    Get Value From Json    ${r_id.json()}    $..sequences[{{loop.index0}}].actions[?(@.type=="slaClass")].parameter[?(@.field=="preferredColor")].value
    ${rec_prefrd_colors_list}=    Split String    ${colors_list[0]}
    ${exp_preferred_colors}=    Create List    {{ (sequence.actions | default({})).sla_class_list.preferred_colors | default([]) | join('   ') }}
    Lists Should Be Equal    ${rec_prefrd_colors_list}    ${exp_preferred_colors}    ignore_order=True    msg=preferred colors
{% endif %}

    ${preferred_color_group_ref_id}=    Get Value From Json    ${r_id.json()}    $..sequences[{{loop.index0}}].actions[?(@.type=="slaClass")].parameter[?(@.field=="preferredColorGroup")].ref
    IF    ${preferred_color_group_ref_id} == []
        Should Be Equal Value Json String    ${r_id.json()}    $..sequences[{{loop.index0}}].actions[?(@.type=="slaClass")].parameter[?(@.field=="preferredColorGroup")].ref    {{ (sequence.actions | default({})).sla_class_list.preferred_color_group | default("not_defined") }}    msg=preferred color group
    ELSE
        ${preferred_color_group_match_id}=   GET On Session   sdwan_manager   /dataservice/template/policy/list/preferredcolorgroup/${preferred_color_group_ref_id[0]}
        Should Be Equal Value Json String    ${preferred_color_group_match_id.json()}    $..name    {{ (sequence.actions | default({})).sla_class_list.preferred_color_group | default("not_defined") }}    msg=preferred color group
    END

{% if (sequence.actions | default({})).sla_class_list.when_sla_not_met is defined and (sequence.actions | default({})).sla_class_list.when_sla_not_met != "load_balance" %}
{% set exp_sla = ({"fallback_to_best_path":"fallbackToBestPath", "strict_drop":"strict"}) %}
    ${rec_data}=    Get Value From Json    ${r_id.json()}    $..sequences[{{loop.index0}}].actions[?(@.type=="slaClass")].parameter[?(@.field)].field
    List Should Contain Value    ${rec_data}    {{ exp_sla[(sequence.actions | default({})).sla_class_list.when_sla_not_met] | default("not_defined") }}    msg=when sla not met
{% else %}
    ${rec_data}=    Get Value From Json    ${r_id.json()}    $..sequences[{{loop.index0}}].actions[?(@.type=="slaClass")].parameter[?(@.field)].field
    List Should Not Contain Value    ${rec_data}    fallbackToBestPath    msg=when sla not met
    List Should Not Contain Value    ${rec_data}    strict    msg=when sla not met
{% endif %}

{% endfor %}

{% endfor %}

{% endif %}
