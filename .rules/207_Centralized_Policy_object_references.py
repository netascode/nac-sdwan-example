class Rule:
    id = "207"
    description = "Verify Centralized Policy object references"
    severity = "HIGH"
    
    # # Verify Policy Definition and policies have the referenced policy objects available
    policy_definition_type = [
        'control_policy', 'data_policy'
    ]
    policy_definition_sub_type = [
        'hub_and_spoke_topology', 'mesh_topology', 'vpn_membership', 'custom_control_topology', 'traffic_data', 'cflowd', 'application_aware_routing'
    ] 

    feature_policies_with_objects = [
        'custom_control_topology', 'traffic_data', 'cflowd', 'application_aware_routing'
    ] 

    policy_definition_sub_branches = [
        'match_criterias', 'actions'
    ]

    policy_definition_sub_branches_cp = [
        'hub_and_spoke_sites', 'mesh_groups', 'groups'
    ]

    policy_object_reference = {
        'color_list': 'color_lists',
        'site_list': 'site_lists',
        'site_lists': 'site_lists',
        'site_lists_in': 'site_lists',
        'site_lists_out': 'site_lists',
        'community_list': 'standard_community_lists',
        'expanded_community_list': 'expanded_community_lists',
        'tloc_list': 'tloc_lists',
        'vpn_list': 'vpn_lists',
        'vpn_lists': 'vpn_lists',
        'export_to_vpn_list' : 'vpn_lists',
        'ipv4_prefix_list': 'ipv4_prefix_lists',
        'ipv4_prefix_lists': 'ipv4_prefix_lists',
        'application_list': 'application_lists',
        'cloud_saas_application_list': 'application_lists',
        'dns_application_list': 'application_lists',
        'source_data_prefix_list': 'ipv4_data_prefix_lists',
        'destination_data_prefix_list': 'ipv4_data_prefix_lists',
        'preferred_color_group': 'preferred_color_groups',
        'policer_list': 'policers',
        'region_list': 'region_lists',
        'region_lists': 'region_lists',
        'region_lists_in': 'region_lists',
        'region_lists_out': 'region_lists',
        'sla_class_list': 'sla_classes',
        'default_action_sla_class_list': 'sla_classes'
    }

    # Extract the Policy Object Names defined in the Policy Objects at ['sdwan']['policy_objects'][.]
    @classmethod
    def policy_objects(cls, inventory):
        results = {}
        for pot in cls.policy_object_reference:
            results[pot] = []
            try:
                for pobjs in inventory['sdwan']['policy_objects'][cls.policy_object_reference[pot]]:
                    results[pot].append(pobjs['name'])
            except KeyError:
                continue
        return results

    # Create a standardized dictionary for the results
    @classmethod
    def make_dict(cls, name, sequence, objtype, policy_objects_name, pdtype, pdsubtype, obj, objname):
        result_dict = {}
        result_dict['name'] = name
        result_dict['sequence'] = sequence
        result_dict['type'] = objtype
        result_dict['policy_objects_name'] = policy_objects_name
        result_dict['pdtype'] = pdtype
        result_dict['pdsubtype'] = pdsubtype
        result_dict[str(obj)] = objname
        return result_dict

    # Extract the Policy Definition Names defined in the Centralized Policies at the following paths
    # ['sdwan']['centralized_policies']['definitions'][.][.]
    # ['sdwan']['centralized_policies']['feature_policies']
    @classmethod
    def definitions(cls, inventory):
        results = []
        for pot in cls.policy_object_reference:
            for w in cls.policy_definition_type:
                for x in cls.policy_definition_sub_type:
                    # Policy objects in policy definition
                    try:
                        for ds in inventory['sdwan']['centralized_policies']['definitions'][w][x]:
                            try:
                                # Policy objects at policy definition root
                                if pot in ds:
                                    results.append(cls.make_dict(ds['name'], "n/a", pot, cls.policy_object_reference[pot], w, x, pot, ds[pot]))
                                # Policy objects under paths in policy_definition_sub_branches
                                if "sequences" in ds:
                                    for seq in ds['sequences']:
                                        for y in cls.policy_definition_sub_branches:
                                            if y in seq:
                                                if pot in seq[y]:
                                                    # Special handling for nested sla_class_list structure
                                                    if pot == 'sla_class_list' and isinstance(seq[y][pot], dict) and 'sla_class_list' in seq[y][pot]:
                                                        results.append(cls.make_dict(ds['name'], seq['name'], pot, cls.policy_object_reference[pot], w, x, pot, seq[y][pot]['sla_class_list']))
                                                    else:
                                                        results.append(cls.make_dict(ds['name'], seq['name'], pot, cls.policy_object_reference[pot], w, x, pot, seq[y][pot]))
                                                # Policy objects under 'service' in policy_definition_sub_branches
                                                if "service" in seq[y]:
                                                    if pot in seq[y]['service']:
                                                        results.append(cls.make_dict(ds['name'], seq['name'], pot, cls.policy_object_reference[pot], w, x, pot, seq[y]['service'][pot]))
                                for reference_branches in cls.policy_definition_sub_branches_cp:
                                    if reference_branches in ds:
                                        # Policy objects under policy_definition_sub_branches_cp
                                        for sites in ds[reference_branches]:
                                            if pot in sites:
                                                # if policy object is a list
                                                if isinstance(sites[pot], list):
                                                    for siteobj in sites[pot]:
                                                        results.append(cls.make_dict(ds['name'], "n/a", pot, cls.policy_object_reference[pot], w, x, pot, siteobj))
                                                # if policy object is not a list
                                                else:
                                                    results.append(cls.make_dict(ds['name'], "n/a", pot, cls.policy_object_reference[pot], w, x, pot, sites[pot]))
                                            # Policy objects under spokes of the hub_and_spoke_sites
                                            if 'spokes' in sites:
                                                for spokes in sites['spokes']:
                                                    if pot in spokes:
                                                        results.append(cls.make_dict(ds['name'], sites['name'], pot, cls.policy_object_reference[pot], w, x, pot, spokes[pot]))
                                                    if 'hubs' in spokes:
                                                        for hubs in spokes['hubs']:
                                                            if pot in hubs:
                                                                # if policy object is a list
                                                                if isinstance(hubs[pot], list):
                                                                    for hubobj in hubs[pot]:
                                                                        results.append(cls.make_dict(ds['name'], sites['name'], pot, cls.policy_object_reference[pot], w, x, pot, hubobj))
                                                                # if policy object is not a list
                                                                else:
                                                                    results.append(cls.make_dict(ds['name'], sites['name'], pot, cls.policy_object_reference[pot], w, x, pot, hubs[pot]))
                            except Exception:
                                continue
                    except KeyError:
                        continue
            # Policy objects in feature policies
            try:
                for x in cls.feature_policies_with_objects:
                    for ds in inventory['sdwan']['centralized_policies']['feature_policies']:
                        if x in ds:
                            # Policy objects in Level 1 branch of feature policies
                            for pd in ds[x]:
                                try:
                                    if pot in pd:
                                        # if policy object is a list
                                        if isinstance(pd[pot], list):
                                            for pdobj in pd[pot]:
                                                results.append(cls.make_dict(ds['name'], "n/a", pot, cls.policy_object_reference[pot], "feature_policies", x, pot, pdobj))
                                        # if policy object is not a list
                                        else:
                                            results.append(cls.make_dict(ds['name'], "n/a", pot, cls.policy_object_reference[pot], "feature_policies", x, pot, pd[pot]))
                                    # Policy objects in Level 2 branch of feature policies
                                    for pdd in pd:
                                        # Case 1: Level 2 value is a dict
                                        if isinstance(pd[pdd], dict):
                                            if pot in pd[pdd]:
                                                # if policy object is a list
                                                if isinstance(pd[pdd][pot], list):
                                                    for pdobj in pd[pdd][pot]:
                                                        results.append(cls.make_dict(ds['name'], "n/a", pot, cls.policy_object_reference[pot], "feature_policies", x, pot, pdobj))
                                                # if policy object is not a list
                                                else:
                                                    results.append(cls.make_dict(ds['name'], "n/a", pot, cls.policy_object_reference[pot], "feature_policies", x, pot, pd[pdd][pot]))
                                        # Case 2: Level 2 value is a list (e.g., site_region_vpn in traffic_data)
                                        elif isinstance(pd[pdd], list):
                                            for list_item in pd[pdd]:
                                                if isinstance(list_item, dict) and pot in list_item:
                                                    # if policy object is a list
                                                    if isinstance(list_item[pot], list):
                                                        for pdobj in list_item[pot]:
                                                            results.append(cls.make_dict(ds['name'], "n/a", pot, cls.policy_object_reference[pot], "feature_policies", x, pot, pdobj))
                                                    # if policy object is not a list
                                                    else:
                                                        results.append(cls.make_dict(ds['name'], "n/a", pot, cls.policy_object_reference[pot], "feature_policies", x, pot, list_item[pot]))
                                except Exception:
                                    continue
            except KeyError:
                continue
        return results  

    # Compare the Policy objects referenced in the Centralized Policies at ['sdwan']['centralized_policies']['feature_policies'] 
    # and ['sdwan']['centralized_policies']['definitions'][.][.] to the Policy objects defined in the Policy Objects at ['sdwan']['policy_objects'][.]
    # and find the missing Policy Objects
    @classmethod
    def match(cls, inventory):
        definitions = cls.definitions(inventory)
        policy_objects = cls.policy_objects(inventory)
        missing_policy_objects = []
        for x in definitions:
            if x[str(x['type'])] not in policy_objects[x['type']]:
                missing_policy_objects.append(str("Missing Policy object '" + x[str(x['type'])] + "' at ['sdwan']['policy_objects']['" + x['policy_objects_name'] + "'] referenced under ['sdwan']['centralized_policies']['definitions']['" + x['pdtype'] +"']['" + x['pdsubtype'] +"'] name: '" + x['name'] + "', sequence name: '" + x['sequence']+ "'"))
        return missing_policy_objects