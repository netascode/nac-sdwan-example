class Rule:
    id = "201"
    description = "Verify Feature Template and Policy references in Device Template"
    severity = "HIGH"
    
    # Feature Templates can be referenced in Device Templates at ['sdwan']['edge_device_templates'] in 3 levels
    feature_template_level1 = ['system_template', 'logging_template', 'ntp_template', 'aaa_template', 'bfd_template', 'omp_template', 'security_template', 'vpn_0_template', 'vpn_512_template', 'vpn_service_templates', 'global_settings_template', 'banner_template', 'snmp_template', 'cli_template', 'switchport_templates', 'thousandeyes_template', 'cellular_controller_templates']
    
    feature_template_level2 = ['bgp_template', 'ethernet_interface_templates', 'igmp_template', 'ipsec_interface_templates', 'svi_interface_templates', 'multicast_template', 'ospf_template', 'pim_template', 'secure_internet_gateway_template', 'sig_credentials_template', 'container_profile', 'cellular_profile_templates', 'gre_interface_templates', 'cellular_interface_templates']
    
    feature_template_level3 = ['dhcp_server_template']
    
    # Feature Templates defined at ['sdwan']['edge_feature_templates']
    edge_feature_templates = ['bgp_templates', 'ethernet_interface_templates', 'igmp_templates', 'ipsec_interface_templates', 'svi_interface_templates', 'multicast_templates', 'ospf_templates', 'pim_templates', 'secure_internet_gateway_templates', 'sig_credentials_templates','system_templates', 'logging_templates', 'ntp_templates', 'aaa_templates', 'bfd_templates', 'omp_templates', 'security_templates', 'vpn_templates', 'global_settings_templates', 'banner_templates', 'snmp_templates', 'cli_templates', 'switchport_templates', 'thousandeyes_templates', 'dhcp_server_templates', 'secure_app_hosting_templates', 'gre_interface_templates', 'cellular_interface_templates', 'cellular_controller_templates', 'cellular_profile_templates']
    
    # Feature Template keys in ['sdwan']['edge_device_templates'] are mapped to the keys in ['sdwan']['edge_feature_templates']
    # as they are not the same in both the places for all scenarios
    feature_template_mapping = {
        'system_template': 'system_templates',
        'logging_template': 'logging_templates',
        'ntp_template': 'ntp_templates',
        'aaa_template': 'aaa_templates',
        'bfd_template': 'bfd_templates',
        'omp_template': 'omp_templates',
        'security_template': 'security_templates',
        'vpn_0_template': 'vpn_templates',
        'vpn_512_template': 'vpn_templates',
        'vpn_service_templates': 'vpn_templates',
        'global_settings_template': 'global_settings_templates',
        'igmp_template': 'igmp_templates',
        'banner_template': 'banner_templates',
        'snmp_template': 'snmp_templates',
        'cli_template' : 'cli_templates',
        'switchport_templates': 'switchport_templates',
        'thousandeyes_template': 'thousandeyes_templates',
        'bgp_template': 'bgp_templates',
        'ethernet_interface_templates': 'ethernet_interface_templates',
        'ipsec_interface_templates': 'ipsec_interface_templates',
        'svi_interface_templates': 'svi_interface_templates',
        'multicast_template': 'multicast_templates',
        'ospf_template': 'ospf_templates',
        'pim_template': 'pim_templates',
        'secure_internet_gateway_template': 'secure_internet_gateway_templates',
        'sig_credentials_template': 'sig_credentials_templates',
        'dhcp_server_template': 'dhcp_server_templates',
        'container_profile': 'secure_app_hosting_templates',
        'gre_interface_templates': 'gre_interface_templates',
        'cellular_interface_templates': 'cellular_interface_templates',
        'cellular_controller_templates': 'cellular_controller_templates',
        'cellular_profile_templates': 'cellular_profile_templates'
    }

    # Extract the Feature Template names referenced in Device Templates at ['sdwan']['edge_device_templates']
    # Extract the Localized Policy names referenced in Device Templates at ['sdwan']['edge_device_templates']
    # Extract the Security Policy names referenced in Device Templates at ['sdwan']['edge_device_templates']
    @classmethod
    def build_device_template_dict(cls, inventory):
        device_template_dict = {'device_templates': []}
        ## Loop through the device templates
        for device_template in inventory.get("sdwan", {}).get("edge_device_templates", []):
            template = {
                'name': device_template.get('name'), 
                'feature_templates': {},
                'localized_policies': [],
                'security_policies': []
            }
            ## Initialize the list of feature templates for each feature type
            for feature in cls.feature_template_level1:
                template['feature_templates'][feature] = []
            for subfeature in cls.feature_template_level2:
                template['feature_templates'][subfeature] = []
            for subfeature_l3 in cls.feature_template_level3:
                template['feature_templates'][subfeature_l3] = []
            ## Add the localized policy to the result dictionary
            if "localized_policy" in device_template:
                template['localized_policies'].append(device_template.get('localized_policy'))
            ## Add the security policy to the result dictionary
            if "security_policy" in device_template:
                template['security_policies'].append(device_template.get('security_policy').get('name'))
                if "container_profile" in device_template.get('security_policy'):
                    template['feature_templates']['container_profile'].append(device_template.get('security_policy').get('container_profile'))
            ## Loop through the feature templates in the device template at Level 1
            for feature in cls.feature_template_level1:
                feature_val = device_template.get(feature)
                if feature_val:
                    ## Check if the feature template is a dictionary
                    if isinstance(feature_val, dict):
                        template['feature_templates'][feature].extend([feature_val.get('name')])
                        ## Loop through the feature templates in the device template at Level 2
                        for subfeature in cls.feature_template_level2:
                            subfeature_val = feature_val.get(subfeature)
                            if subfeature_val:
                                if isinstance(subfeature_val, list):
                                    template['feature_templates'][subfeature].extend([subfeat.get('name') for subfeat in subfeature_val if isinstance(subfeat, dict)])
                                    for subfeat in subfeature_val:
                                        ## Loop through the feature templates in the device template at Level 3
                                        for subfeature_l3 in cls.feature_template_level3:
                                            subfeature_val_l3 = subfeat.get(subfeature_l3)
                                            if subfeature_val_l3:
                                                if isinstance(subfeature_val_l3, list):
                                                    template['feature_templates'][subfeature_l3].extend([subfeat.get('name') for subfeat in subfeature_val_l3 if isinstance(subfeat, dict)])
                                                else:
                                                    template['feature_templates'][subfeature_l3].append(subfeature_val_l3)
                                else:
                                    template['feature_templates'][subfeature].append(subfeature_val)
                    ## Check if the feature template is a list
                    elif isinstance(feature_val, list):
                        template['feature_templates'][feature].extend([feat.get('name') for feat in feature_val if isinstance(feat, dict)])
                        for feat in feature_val:
                            ## Loop through the feature templates in the device template at Level 2
                            for subfeature in cls.feature_template_level2:
                                subfeature_val = feat.get(subfeature)
                                if subfeature_val:
                                    if isinstance(subfeature_val, list):
                                        template['feature_templates'][subfeature].extend([subfeat.get('name') for subfeat in subfeature_val if isinstance(subfeat, dict)])
                                        for subfeat in subfeature_val:
                                            ## Loop through the feature templates in the device template at Level 3
                                            for subfeature_l3 in cls.feature_template_level3:
                                                subfeature_val_l3 = subfeat.get(subfeature_l3)
                                                if subfeature_val_l3:
                                                    if isinstance(subfeature_val_l3, list):
                                                        template['feature_templates'][subfeature_l3].extend([subfeat.get('name') for subfeat in subfeature_val_l3 if isinstance(subfeat, dict)])
                                                    else:
                                                        template['feature_templates'][subfeature_l3].append(subfeature_val_l3)
                                    else:
                                        template['feature_templates'][subfeature].append(subfeature_val)
                    else:
                        template['feature_templates'][feature].extend([feature_val])
            device_template_dict['device_templates'].append(template)
        return device_template_dict

    # Extract the Feature Template names at ['sdwan']['edge_feature_templates']
    @classmethod
    def build_feature_template_dict(cls, inventory):
        feature_templates_data = inventory.get("sdwan", {}).get("edge_feature_templates", {})
        feature_template_dictionary = {}
        for feature_type in cls.edge_feature_templates:
            feature_template_dictionary[feature_type] = [
                feature.get("name") for feature in feature_templates_data.get(feature_type, [])
            ]
        return feature_template_dictionary

    # Extract the Policy Names of the Localized Policies at ['sdwan']['localized_policies']['feature_policies']
    @classmethod
    def build_localized_policies_list(cls, inventory):
        results = []
        for fpds in inventory.get('sdwan', {}).get('localized_policies', {}).get('feature_policies', {}):
            results.append(fpds['name'])
        return results 
    
    # Extract the Policy Names of the Security Policies at ['sdwan']['security_policies']['definitions']
    @classmethod
    def build_security_policies_list(cls, inventory):
        results = []
        for fpds in inventory.get('sdwan', {}).get('security_policies', {}).get('feature_policies', {}):
            results.append(fpds['name'])
        return results 

    # Validate if the Feature Template names referenced in Device Templates at ['sdwan']['edge_device_templates'] are defined at ['sdwan']['edge_feature_templates']
    # Validate if the Localized Policy names referenced in Device Templates at ['sdwan']['edge_device_templates'] are defined at ['sdwan']['localized_policies']['feature_policies']
    # Validate if the Security Policy names referenced in Device Templates at ['sdwan']['edge_device_templates'] are defined at ['sdwan']['security_policies']['feature_policies']
    @classmethod
    def match(cls, inventory):
        results = []
        device_template_dict = cls.build_device_template_dict(inventory)
        feature_template_dictionary = cls.build_feature_template_dict(inventory)
        build_localized_policies_list = cls.build_localized_policies_list(inventory)
        build_security_policies_list = cls.build_security_policies_list(inventory)
        for device_template in device_template_dict.get("device_templates", []):
            for feature_type, feature_templates in device_template.get("feature_templates", {}).items():
                for template_name in feature_templates:
                    if template_name not in feature_template_dictionary.get(cls.feature_template_mapping[feature_type], []):
                        results.append(
                            f"Validation Error: feature_template:'{template_name}' in device_template:'{device_template.get('name')}' is not a defined in [sdwan][edge_feature_templates][{cls.feature_template_mapping[feature_type]}]\n"
                        )
            for localized_policy in device_template.get("localized_policies", []):
                if localized_policy not in build_localized_policies_list:
                    results.append(
                        f"Validation Error: localized_policy:'{localized_policy}' in device_template:'{device_template.get('name')}' is not a defined in [sdwan][localized_policies][feature_policies]\n"
                    )
            for security_policy in device_template.get("security_policies", []):
                if security_policy not in build_security_policies_list:
                    results.append(
                        f"Validation Error: security_policy:'{security_policy}' in device_template:'{device_template.get('name')}' is not a defined in [sdwan][security_policies][feature_policies]\n"
                    )
        return results