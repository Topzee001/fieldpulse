# apps/checklists/utils.py

import re
from typing import Dict, Any, List, Tuple

def validate_checklist_value(value: Any, field_schema: Dict) -> List[str]:
    """Validate a single checklist field value against its schema."""
    errors = []
    field_type = field_schema.get('type')
    required = field_schema.get('required', False)
    
    if required and (value is None or value == ''):
        errors.append(f"{field_schema.get('label', 'Field')} is required")
        return errors
    
    if value is None or value == '':
        return errors  # Skip further validation if empty and not required
    
    if field_type == 'text':
        if 'validation' in field_schema:
            vtype = field_schema['validation']
            if vtype == 'email' and not re.match(r'^[\w\.-]+@[\w\.-]+\.\w+$', value):
                errors.append("Invalid email format")
            elif vtype == 'phone' and not re.match(r'^\+?[\d\s\-]{10,}$', value):
                errors.append("Invalid phone number")
            elif vtype == 'number' and not value.isdigit():
                errors.append("Must be a number")
    
    elif field_type == 'number':
        try:
            num = float(value)
            if 'min' in field_schema and num < field_schema['min']:
                errors.append(f"Minimum value is {field_schema['min']}")
            if 'max' in field_schema and num > field_schema['max']:
                errors.append(f"Maximum value is {field_schema['max']}")
        except ValueError:
            errors.append("Must be a number")
    
    elif field_type == 'select':
        allowed = field_schema.get('options', [])
        if value not in allowed:
            errors.append(f"Invalid selection. Allowed: {', '.join(allowed)}")
    
    elif field_type == 'multi_select':
        if not isinstance(value, list):
            errors.append("Must be a list")
        else:
            allowed = set(field_schema.get('options', []))
            invalid = [v for v in value if v not in allowed]
            if invalid:
                errors.append(f"Invalid options: {', '.join(invalid)}")
    
    return errors

def validate_checklist_response(data: Dict, schema: Dict) -> Tuple[bool, Dict]:
    """Validate entire checklist response against the job's schema."""
    errors = {}
    fields = schema.get('fields', [])
    for field in fields:
        field_id = field['id']
        value = data.get(field_id)
        field_errors = validate_checklist_value(value, field)
        if field_errors:
            errors[field_id] = field_errors
    return len(errors) == 0, errors