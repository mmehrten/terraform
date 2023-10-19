import json
import os

def recurse_keys(key, properties):
    for prop, meta in properties.items():
        # proptype = meta["type"]
        nextprops = meta.get("properties")
        next_key = f"{key}.{prop}"
        if not nextprops:
            print(next_key.replace(".", "/"))
            continue
        recurse_keys(next_key, nextprops)

def print_mapping_fields(mapping):
    props = mapping["template"]["mappings"]["properties"]
    recurse_keys("parsed", props)

for base in os.listdir("mappings"):
    for mapfile in os.listdir(f"mappings/{base}"):
        with open(f"mappings/{base}/{mapfile}", "r")as f:
            mapping = json.load(f)
            print_mapping_fields(mapping)
