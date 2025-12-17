class Rule:
    id = "404"
    description = "Verify Policy Object unique names in policy objects feature profile"
    severity = "HIGH"

    @classmethod
    def match(cls, inventory):
        results = []
        object_names = []
        for objects in inventory.get('sdwan', {}).get('feature_profiles', {}).get("policy_object_profile", {}).values():
            if type(objects) is list:
                for object in objects:
                    object_names.append(object['name'])
        non_unique_names = [name for name in set(object_names) if object_names.count(name) > 1]
        for name in non_unique_names:
             results.append(f"Policy Object name '{name}' is not unique")

        return results