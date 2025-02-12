import { TextFieldSingleValidation } from 'payload'

export const validateHexColorDisabled = (value: string = ''): true | string => {
  return value.match(/^#(?:[0-9a-fA-F]{3}){1,2}$/) !== null || `Please give a valid hex color`
}

export const validateHexColor: TextFieldSingleValidation = (
  value: string | null | undefined = '',
): true | string => {
  return value && /^#(?:[0-9a-fA-F]{3}){1,2}$/.test(value) ? true : `Please give a valid hex color`
}
