# 2.4.16

- Keep CarPlay usable when optional local artwork is missing or corrupt. Contain image conversion errors across native template creation and updates, preserve existing list images, and retain image-row positions.

# 2.4.15

- Preserve top-level section arrays when serializing list updates, including an empty list. Prevents an Objective-C section parsing exception.
- Resolve Android dependencies from Maven Central.
