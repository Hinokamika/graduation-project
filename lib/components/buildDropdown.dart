import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:flutter/material.dart';

Widget buildDropdown({
  required String? value,
  required String label,
  required IconData icon,
  required List<String> items,
  required void Function(String?) onChanged,
  String? hintText,
  bool enabled = true,
  String? Function(String?)? validator,
}) {
  return Builder(
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            prefixIcon: Icon(
              icon,
              color: enabled
                  ? AppColors.primary
                  : AppColors.getTextTertiary(context),
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.getBorder(context),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.getBorder(context),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.getBorder(context).withOpacity(0.5),
                width: 1,
              ),
            ),
            filled: true,
            fillColor: AppColors.getSurface(context),
            labelStyle: AppTextStyles.label.copyWith(
              color: AppColors.getTextSecondary(context),
            ),
            hintStyle: AppTextStyles.hint.copyWith(
              color: AppColors.getTextTertiary(context),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.getTextPrimary(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
          validator:
              validator ??
              (value) => value == null ? 'Please select $label' : null,
          menuMaxHeight: 300,
          dropdownColor: AppColors.getSurface(context),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.getTextPrimary(context),
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.getTextSecondary(context),
          ),
        ),
      );
    },
  );
}
