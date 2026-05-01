import { AppError } from '../middleware/errorHandler';
import { ErrorCodes } from '../errors/codes';

export function validateString(value: unknown, field: string, min = 1, max = 100): string {
  if (typeof value !== 'string') {
    throw new AppError(`${field} must be a string`, 400, ErrorCodes.VALIDATION_ERROR);
  }
  const trimmed = value.trim();
  if (trimmed.length < min) {
    throw new AppError(`${field} is required`, 400, ErrorCodes.VALIDATION_ERROR);
  }
  if (trimmed.length > max) {
    throw new AppError(`${field} must be at most ${max} characters`, 400, ErrorCodes.VALIDATION_ERROR);
  }
  return trimmed;
}
