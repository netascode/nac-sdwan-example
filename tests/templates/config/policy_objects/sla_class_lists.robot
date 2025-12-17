*** Settings ***
Documentation   Verify Sla Class Lists
Suite Setup     Login SDWAN Manager
Suite Teardown  Run On Last Process   Logout SDWAN Manager
Default Tags    sdwan   config   classic_policy_objects
Resource        ../../sdwan_common.resource

{% if sdwan.policy_objects is defined and sdwan.policy_objects.sla_classes is defined %}

*** Test Cases ***
Get Sla Class List(s)
   ${r}=   GET On Session   sdwan_manager   /dataservice/template/policy/list/sla
   Set Suite Variable   ${r}

{% for sla in sdwan.policy_objects.sla_classes | default([]) %}
{% if sla.name is defined %}

Verify Policy Objects SLA Class List {{ sla.name }}
   ${sla_class_id}=   Get Value From Json   ${r.json()}   $..data[?(@..name=="{{ sla.name }}")].listId
   ${sla}=   GET On Session   sdwan_manager   /dataservice/template/policy/list/sla/${sla_class_id[0]}
   Should Be Equal Value Json String   ${sla.json()}   $..name  {{ sla.name }}   msg=SLA class name
   Should Be Equal Value Json String   ${sla.json()}   $..jitter   {{ sla.jitter_ms | default("not_defined") }}  msg={{ sla.name }}: Jitter
   Should Be Equal Value Json String   ${sla.json()}   $..latency   {{ sla.latency_ms | default("not_defined") }}  msg={{ sla.name }}: Latency
   Should Be Equal Value Json String   ${sla.json()}   $..loss   {{ sla.loss_percentage | default("not_defined") }}  msg={{ sla.name }}: Loss

   ${app_probe_id}=   Get Value From Json   ${sla.json()}   $..appProbeClass
{% if sla.app_probe_class | default("not_defined") == "not_defined" %}
   Should Be Empty   ${app_probe_id}  msg={{ sla.name }}: App Probe Class
{% else %}
   ${app_probe_object}=   GET On Session   sdwan_manager   /dataservice/template/policy/list/appprobe/${app_probe_id[0]}
   Should Be Equal Value Json String   ${app_probe_object.json()}   $..name   {{ sla.app_probe_class }}  msg={{ sla.name }}: App Probe Class
{% endif %}

   Should Be Equal Value Json String   ${sla.json()}   $..criteria   {{ sla.fallback_best_tunnel_criteria | default("not_defined") }}  msg={{ sla.name }}: Loss Criteria
   Should Be Equal Value Json String   ${sla.json()}   $..jitterVariance   {{ sla.fallback_best_tunnel_jitter | default("not_defined") }}  msg={{ sla.name }}: Jitter Variance
   Should Be Equal Value Json String   ${sla.json()}   $..latencyVariance   {{ sla.fallback_best_tunnel_latency | default("not_defined") }}  msg={{ sla.name }}: Latency Variance
   Should Be Equal Value Json String   ${sla.json()}   $..lossVariance   {{ sla.fallback_best_tunnel_loss | default("not_defined") }}  msg={{ sla.name }}: Loss Variance
{% endif %}

{% endfor %}
{% endif %}
