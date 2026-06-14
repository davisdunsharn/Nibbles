// Error handling utilities for consistent error management across the app

export class AppError extends Error {
  constructor(message, code = 'ERROR', details = null) {
    super(message)
    this.code = code
    this.details = details
    this.timestamp = new Date()
  }
}

// Categorize and handle different error types
export function handleError(error, context = '') {
  console.error(`[${context}]`, error)

  let message = 'An unexpected error occurred'
  let code = 'UNKNOWN_ERROR'

  if (error instanceof AppError) {
    message = error.message
    code = error.code
  } else if (error?.message?.includes('Invalid login credentials')) {
    message = 'Invalid email or password'
    code = 'AUTH_ERROR'
  } else if (error?.message?.includes('User already exists')) {
    message = 'This email is already in use'
    code = 'DUPLICATE_USER'
  } else if (error?.message?.includes('FOREIGN KEY constraint failed')) {
    message = 'Cannot delete: item is in use elsewhere'
    code = 'CONSTRAINT_ERROR'
  } else if (error?.status === 409) {
    message = 'This record already exists'
    code = 'CONFLICT'
  } else if (error?.status === 404) {
    message = 'Record not found'
    code = 'NOT_FOUND'
  } else if (error?.status === 403) {
    message = 'You do not have permission to perform this action'
    code = 'FORBIDDEN'
  } else if (error?.status >= 500) {
    message = 'Server error - please try again later'
    code = 'SERVER_ERROR'
  } else if (error?.message) {
    message = error.message
  }

  return { message, code, details: error?.details || null }
}

// Validate form inputs before submission
export function validateForm(data, rules) {
  const errors = {}

  for (const [field, value] of Object.entries(data)) {
    if (!rules[field]) continue

    const fieldRules = rules[field]

    // Required validation
    if (fieldRules.required && (!value || value === '')) {
      errors[field] = `${fieldRules.label || field} is required`
      continue
    }

    // Min length
    if (fieldRules.minLength && value?.length < fieldRules.minLength) {
      errors[field] = `${fieldRules.label || field} must be at least ${fieldRules.minLength} characters`
      continue
    }

    // Max length
    if (fieldRules.maxLength && value?.length > fieldRules.maxLength) {
      errors[field] = `${fieldRules.label || field} cannot exceed ${fieldRules.maxLength} characters`
      continue
    }

    // Email format
    if (fieldRules.email && value && !validateEmail(value)) {
      errors[field] = 'Please enter a valid email address'
      continue
    }

    // Min value
    if (fieldRules.min !== undefined && value < fieldRules.min) {
      errors[field] = `${fieldRules.label || field} must be at least ${fieldRules.min}`
      continue
    }

    // Max value
    if (fieldRules.max !== undefined && value > fieldRules.max) {
      errors[field] = `${fieldRules.label || field} cannot exceed ${fieldRules.max}`
      continue
    }

    // Custom validation
    if (fieldRules.custom && !fieldRules.custom(value)) {
      errors[field] = fieldRules.customMessage || `${fieldRules.label || field} is invalid`
    }
  }

  return errors
}

export function validateEmail(email) {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return re.test(email)
}

export function validatePhoneNumber(phone) {
  // South Africa phone format: +27 or 0 followed by digits
  const re = /^(?:\+27|0)\d{9}$/
  return re.test(phone.replace(/\s+/g, ''))
}

// Safe async operation wrapper
export async function safeAsync(asyncFn, context = 'Operation') {
  try {
    return { data: await asyncFn(), error: null }
  } catch (error) {
    const { message, code } = handleError(error, context)
    return { data: null, error: { message, code, original: error } }
  }
}

// Retry logic for failed operations
export async function retryAsync(asyncFn, maxRetries = 3, delayMs = 1000) {
  let lastError
  
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await asyncFn()
    } catch (error) {
      lastError = error
      console.warn(`Attempt ${attempt}/${maxRetries} failed:`, error.message)
      
      if (attempt < maxRetries) {
        await new Promise(resolve => setTimeout(resolve, delayMs * attempt))
      }
    }
  }
  
  throw lastError
}
