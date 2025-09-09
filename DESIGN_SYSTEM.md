# Healthcare+ App - Minimalist Design System

## 🎨 Color Palette

### Primary Colors

- **Primary**: `#2C3E50` - Deep slate blue-gray for headers and important text
- **Primary Light**: `#34495E` - Lighter slate for secondary elements
- **Accent**: `#3498DB` - Clean blue accent for interactive elements

### Neutral Colors

- **White**: `#FFFFFF` - Pure white for backgrounds
- **Background**: `#FAFAFA` - Off-white background for pages
- **Surface**: `#F8F9FA` - Card and input field surfaces
- **Divider**: `#E9ECEF` - Subtle dividers and borders

### Text Colors

- **Text Primary**: `#2C3E50` - Primary text content
- **Text Secondary**: `#6C757D` - Secondary text and labels
- **Text Light**: `#8E9BAE` - Light text and hints

### Status Colors

- **Success**: `#27AE60` - Success states and positive feedback
- **Warning**: `#F39C12` - Warning states and cautions
- **Error**: `#E74C3C` - Error states and alerts
- **Info**: `#3498DB` - Informational content

### Healthcare Specific

- **Health Primary**: `#5DADE2` - Calming blue for health elements
- **Health Secondary**: `#AED6F1` - Light health blue for backgrounds
- **Wellness**: `#58D68D` - Wellness and positive health indicators

## 📝 Typography

### Headings

- **Heading 1**: 32px, Bold (700), Primary text color
- **Heading 2**: 24px, Semi-bold (600), Primary text color
- **Heading 3**: 20px, Semi-bold (600), Primary text color

### Body Text

- **Body Large**: 16px, Regular (400), Primary text color
- **Body Medium**: 14px, Regular (400), Secondary text color
- **Body Small**: 12px, Regular (400), Light text color

### Interactive Elements

- **Button**: 16px, Semi-bold (600), White text
- **Button Small**: 14px, Medium (500), Context color
- **Label**: 14px, Medium (500), Primary text color
- **Input**: 16px, Regular (400), Primary text color
- **Hint**: 16px, Regular (400), Light text color

## 🏗️ Design Principles

### Minimalism

- Clean, uncluttered layouts
- Plenty of white space
- Subtle borders and shadows
- Focus on content over decoration

### Accessibility

- High contrast text colors
- Clear visual hierarchy
- Consistent interactive elements
- Touch-friendly button sizes (52px height minimum)

### Healthcare Focus

- Calming, trustworthy color palette
- Professional appearance
- Clear, readable typography
- Stress-free user experience

## 🎯 Component Styling

### Input Fields

- Surface background (`#F8F9FA`)
- Divider border (`#E9ECEF`)
- Accent focus border (`#3498DB`)
- 16px padding, 12px border radius

### Buttons

- Primary: Accent background (`#3498DB`)
- 52px height for accessibility
- 12px border radius
- No elevation/shadows

### Cards and Containers

- Surface background (`#F8F9FA`)
- Subtle divider borders
- 12px border radius
- Minimal shadows

### Status Messages

- Color-coded backgrounds (10% opacity)
- Matching border colors
- Clear, readable text
- Rounded corners for friendliness

## 🔄 Implementation

The design system is implemented through:

- `AppColors` class in `lib/utils/app_colors.dart`
- `AppTextStyles` class in `lib/utils/text_styles.dart`
- Consistent usage across all UI components

This minimalist approach ensures a calming, professional healthcare experience while maintaining excellent usability and accessibility.
