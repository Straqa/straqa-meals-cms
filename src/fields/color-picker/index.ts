import { TextField } from 'payload'

import { validateHexColor } from './config'

export const colorField: TextField = {
  name: 'color',
  type: 'text',
  validate: validateHexColor,
  required: true,
  admin: {
    components: {
      Field: {
        path: '@/fields/color-picker/ColorPickerComponent#ColorInputField',
      },
      Cell: {
        path: '@/fields/color-picker/ColorPickerComponent#ColorPickerCell',
      },
    },
  },
}
