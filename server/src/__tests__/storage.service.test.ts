import { ErrorCodes } from '../errors/codes';
jest.mock('../config/adminDb', () => ({
  supabaseAdmin: {
    storage: {
      from: jest.fn(),
    },
  },
}));

import { getUploadSignedUrl, deleteLogoByUrl } from '../services/storage.service';
import { supabaseAdmin } from '../config/adminDb';
import { AppError } from '../middleware/errorHandler';

const mockFrom = supabaseAdmin.storage.from as jest.Mock;

function makeStorageMock({
  signedUrl = 'https://signed.url/upload',
  path = 'user-1/1234567890.png',
  publicUrl = 'https://supabase.co/storage/v1/object/public/logos/user-1/1234567890.png',
  uploadError = null as null | { message: string },
  removeError = null as null | { message: string },
} = {}) {
  const getPublicUrl = jest.fn().mockReturnValue({ data: { publicUrl } });
  const createSignedUploadUrl = jest
    .fn()
    .mockResolvedValue(
      uploadError
        ? { data: null, error: uploadError }
        : { data: { signedUrl, path }, error: null },
    );
  const remove = jest.fn().mockResolvedValue({ error: removeError });
  mockFrom.mockReturnValue({ createSignedUploadUrl, getPublicUrl, remove });
  return { createSignedUploadUrl, getPublicUrl, remove };
}

beforeEach(() => jest.clearAllMocks());

describe('getUploadSignedUrl', () => {
  it('returns signedUrl, publicUrl and path for valid PNG', async () => {
    makeStorageMock();
    const result = await getUploadSignedUrl('user-1', 'logo.png');
    expect(result.signedUrl).toBe('https://signed.url/upload');
    expect(result.publicUrl).toContain('public/logos/');
    expect(result.path).toMatch(/^user-1\/\d+\.png$/);
  });

  it('accepts jpg, jpeg, gif, webp extensions', async () => {
    for (const ext of ['jpg', 'jpeg', 'gif', 'webp']) {
      makeStorageMock();
      await expect(getUploadSignedUrl('user-1', `logo.${ext}`)).resolves.toBeDefined();
    }
  });

  it('rejects svg (XSS vector)', async () => {
    await expect(getUploadSignedUrl('user-1', 'logo.svg')).rejects.toMatchObject({
      statusCode: 400,
      code: ErrorCodes.VALIDATION_ERROR,
    });
  });

  it('rejects disallowed file extensions', async () => {
    for (const name of ['logo.exe', 'logo.pdf', 'logo.mp4']) {
      await expect(getUploadSignedUrl('user-1', name)).rejects.toThrow(AppError);
    }
  });

  it('throws STORAGE_ERROR when Supabase returns error', async () => {
    makeStorageMock({ uploadError: { message: 'bucket not found' } });
    await expect(getUploadSignedUrl('user-1', 'logo.png')).rejects.toMatchObject({
      statusCode: 500,
      code: ErrorCodes.STORAGE_ERROR,
    });
  });

  it('scopes storage path under userId', async () => {
    const { createSignedUploadUrl } = makeStorageMock();
    await getUploadSignedUrl('user-abc', 'logo.png');
    const calledPath: string = createSignedUploadUrl.mock.calls[0][0];
    expect(calledPath).toMatch(/^user-abc\//);
  });
});

describe('deleteLogoByUrl', () => {
  it('deletes object when URL matches Supabase Storage logos path', async () => {
    const { remove } = makeStorageMock();
    const url =
      'https://xyz.supabase.co/storage/v1/object/public/logos/user-1/1234567890.png';
    await deleteLogoByUrl(url);
    expect(remove).toHaveBeenCalledWith(['user-1/1234567890.png']);
  });

  it('does nothing for non-Supabase URLs', async () => {
    const { remove } = makeStorageMock();
    await deleteLogoByUrl('https://other.cdn.example.com/logo.png');
    expect(remove).not.toHaveBeenCalled();
  });

  it('throws when Supabase removal fails', async () => {
    makeStorageMock({ removeError: { message: 'not found' } });
    const url =
      'https://xyz.supabase.co/storage/v1/object/public/logos/user-1/old.png';
    await expect(deleteLogoByUrl(url)).rejects.toThrow('Failed to delete storage object');
  });
});
