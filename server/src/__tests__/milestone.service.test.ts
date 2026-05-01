import { ErrorCodes } from '../errors/codes';
import { supabaseAdmin } from '../config/adminDb';

jest.mock('../config/adminDb', () => ({
  supabaseAdmin: { from: jest.fn() },
}));

import {
  listMilestones,
  createMilestone,
  updateMilestone,
  deleteMilestone,
} from '../services/milestone.service';

const mockFrom = supabaseAdmin.from as jest.Mock;

// Issue 14 fix: use valid UUID format fixtures
const USER_ID = '00000000-0000-0000-0000-000000000001';
const WORKSPACE_ID = '00000000-0000-0000-0000-000000000002';
const PROJECT_ID = '00000000-0000-0000-0000-000000000003';
const MILESTONE_ID = '00000000-0000-0000-0000-000000000004';

const WORKSPACE_ROW = { id: WORKSPACE_ID };
const PROJECT_ROW = { id: PROJECT_ID };
const MILESTONE_ROW = {
  id: MILESTONE_ID,
  project_id: PROJECT_ID,
  title: 'Beta Launch',
  due_date: '2026-05-11',
  completed: false,
  completed_at: null,
  position: 0,
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-01T00:00:00Z',
};

// getWorkspaceIdForUser: .select('id').eq('owner_id',v).is('deleted_at',null).limit(1)
function makeWsLimitChain(result: { data: unknown; error: unknown }) {
  const limitMock = jest.fn().mockResolvedValue(result);
  const isMock = jest.fn().mockReturnValue({ limit: limitMock });
  const eqMock = jest.fn().mockReturnValue({ is: isMock });
  const selectMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { select: selectMock };
}

// assertProjectOwnership: .select('id').eq('id',v).eq('workspace_id',v).is('deleted_at',null).single()
function makeProjectOwnershipChain(result: { data: unknown; error: unknown }) {
  const singleMock = jest.fn().mockResolvedValue(result);
  const isMock = jest.fn().mockReturnValue({ single: singleMock });
  const eq2Mock = jest.fn().mockReturnValue({ is: isMock });
  const eq1Mock = jest.fn().mockReturnValue({ eq: eq2Mock });
  const selectMock = jest.fn().mockReturnValue({ eq: eq1Mock });
  return { select: selectMock };
}

// listMilestones: .select(cols).eq('project_id',v).order(...)
function makeListChain(result: { data: unknown; error: unknown }) {
  const orderMock = jest.fn().mockResolvedValue(result);
  const eqMock = jest.fn().mockReturnValue({ order: orderMock });
  const selectMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { select: selectMock };
}

// createMilestone: .insert({}).select(cols).single()
function makeInsertChain(result: { data: unknown; error: unknown }) {
  const singleMock = jest.fn().mockResolvedValue(result);
  const selectMock = jest.fn().mockReturnValue({ single: singleMock });
  const insertMock = jest.fn().mockReturnValue({ select: selectMock });
  return { insert: insertMock };
}

// getProjectIdsForWorkspace: .select('id').eq('workspace_id',v).is('deleted_at',null)
function makeProjectIdsChain(result: { data: unknown; error: unknown }) {
  const isMock = jest.fn().mockResolvedValue(result);
  const eqMock = jest.fn().mockReturnValue({ is: isMock });
  const selectMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { select: selectMock };
}

// fetch current milestone state (Issue 4): .select('completed').eq('id',v).in('project_id', ids[]).single()
function makeFetchCurrentChain(result: { data: unknown; error: unknown }) {
  const singleMock = jest.fn().mockResolvedValue(result);
  const inMock = jest.fn().mockReturnValue({ single: singleMock });
  const eqMock = jest.fn().mockReturnValue({ in: inMock });
  const selectMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { select: selectMock };
}

// updateMilestone: .update(payload).eq('id',v).in('project_id', ids[]).select(cols).single()
function makeUpdateChain(result: { data: unknown; error: unknown }) {
  const singleMock = jest.fn().mockResolvedValue(result);
  const selectMock = jest.fn().mockReturnValue({ single: singleMock });
  const inMock = jest.fn().mockReturnValue({ select: selectMock });
  const eq1Mock = jest.fn().mockReturnValue({ in: inMock });
  const updateMock = jest.fn().mockReturnValue({ eq: eq1Mock });
  return { update: updateMock };
}

// deleteMilestone: .delete({count:'exact'}).eq('id',v).in('project_id', ids[])
function makeDeleteChain(result: { error: unknown; count: number | null }) {
  const inMock = jest.fn().mockResolvedValue(result);
  const eqMock = jest.fn().mockReturnValue({ in: inMock });
  const deleteMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { delete: deleteMock };
}

const PROJECT_IDS_RESULT = { data: [{ id: PROJECT_ID }], error: null };
const EMPTY_PROJECT_IDS_RESULT = { data: [], error: null };

beforeEach(() => jest.clearAllMocks());

describe('listMilestones', () => {
  it('returns milestones ordered by position', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: PROJECT_ROW, error: null }))
      .mockReturnValueOnce(makeListChain({ data: [MILESTONE_ROW], error: null }));

    const result = await listMilestones(PROJECT_ID, USER_ID);
    expect(result).toEqual([MILESTONE_ROW]);
  });

  it('returns empty array when no milestones', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: PROJECT_ROW, error: null }))
      .mockReturnValueOnce(makeListChain({ data: null, error: null }));

    const result = await listMilestones(PROJECT_ID, USER_ID);
    expect(result).toEqual([]);
  });

  it('throws NOT_FOUND when project not owned (PGRST116)', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: null, error: { code: 'PGRST116' } }));

    await expect(listMilestones(PROJECT_ID, USER_ID)).rejects.toMatchObject({ code: ErrorCodes.NOT_FOUND });
  });

  it('throws DB_ERROR when assertProjectOwnership has non-PGRST116 DB error', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: null, error: { code: ErrorCodes.INTERNAL_ERROR } }));

    await expect(listMilestones(PROJECT_ID, USER_ID)).rejects.toMatchObject({
      code: ErrorCodes.DB_ERROR,
      statusCode: 500,
    });
  });

  it('throws DB_ERROR on list query failure', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: PROJECT_ROW, error: null }))
      .mockReturnValueOnce(makeListChain({ data: null, error: new Error('db down') }));

    await expect(listMilestones(PROJECT_ID, USER_ID)).rejects.toMatchObject({ code: ErrorCodes.DB_ERROR });
  });
});

describe('createMilestone', () => {
  it('inserts and returns new milestone', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: PROJECT_ROW, error: null }))
      .mockReturnValueOnce(makeInsertChain({ data: MILESTONE_ROW, error: null }));

    const result = await createMilestone(PROJECT_ID, USER_ID, { title: 'Beta Launch' });
    expect(result).toEqual(MILESTONE_ROW);
  });

  it('defaults position to 0 when not provided', async () => {
    const insertChain = makeInsertChain({ data: MILESTONE_ROW, error: null });
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: PROJECT_ROW, error: null }))
      .mockReturnValueOnce(insertChain);

    await createMilestone(PROJECT_ID, USER_ID, { title: 'T' });
    expect(insertChain.insert).toHaveBeenCalledWith(
      expect.objectContaining({ position: 0 }),
    );
  });

  it('passes due_date and position when provided', async () => {
    const insertChain = makeInsertChain({ data: MILESTONE_ROW, error: null });
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: PROJECT_ROW, error: null }))
      .mockReturnValueOnce(insertChain);

    await createMilestone(PROJECT_ID, USER_ID, { title: 'T', due_date: '2026-05-11', position: 2 });
    expect(insertChain.insert).toHaveBeenCalledWith(
      expect.objectContaining({ due_date: '2026-05-11', position: 2 }),
    );
  });

  it('throws NOT_FOUND when project not in workspace (PGRST116)', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: null, error: { code: 'PGRST116' } }));

    await expect(createMilestone(PROJECT_ID, USER_ID, { title: 'T' })).rejects.toMatchObject({
      code: ErrorCodes.NOT_FOUND,
      statusCode: 404,
    });
  });

  it('throws DB_ERROR on insert failure', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectOwnershipChain({ data: PROJECT_ROW, error: null }))
      .mockReturnValueOnce(makeInsertChain({ data: null, error: new Error('db down') }));

    await expect(createMilestone(PROJECT_ID, USER_ID, { title: 'T' })).rejects.toMatchObject({
      code: ErrorCodes.DB_ERROR,
    });
  });
});

describe('updateMilestone', () => {
  it('updates title and returns updated row', async () => {
    const updated = { ...MILESTONE_ROW, title: 'Phase 2' };
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(makeUpdateChain({ data: updated, error: null }));

    const result = await updateMilestone(MILESTONE_ID, USER_ID, { title: 'Phase 2' });
    expect(result.title).toBe('Phase 2');
  });

  it('sets completed_at when transitioning false → true', async () => {
    const updateChain = makeUpdateChain({ data: { ...MILESTONE_ROW, completed: true, completed_at: '2026-05-01T00:00:00Z' }, error: null });
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(makeFetchCurrentChain({ data: { completed: false }, error: null }))
      .mockReturnValueOnce(updateChain);

    await updateMilestone(MILESTONE_ID, USER_ID, { completed: true });
    const payload = (updateChain.update as jest.Mock).mock.calls[0][0] as Record<string, unknown>;
    expect(payload.completed).toBe(true);
    expect(typeof payload.completed_at).toBe('string');
    expect(payload.completed_at).not.toBeNull();
  });

  it('throws DB_ERROR when fetch-current returns a DB error on completed:true path', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(makeFetchCurrentChain({ data: null, error: { code: ErrorCodes.INTERNAL_ERROR } }));

    await expect(updateMilestone(MILESTONE_ID, USER_ID, { completed: true })).rejects.toMatchObject({
      code: ErrorCodes.DB_ERROR,
      statusCode: 500,
    });
  });

  it('does NOT overwrite completed_at when already completed (idempotent)', async () => {
    const updateChain = makeUpdateChain({ data: { ...MILESTONE_ROW, completed: true, completed_at: '2026-04-01T00:00:00Z' }, error: null });
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(makeFetchCurrentChain({ data: { completed: true }, error: null }))
      .mockReturnValueOnce(updateChain);

    await updateMilestone(MILESTONE_ID, USER_ID, { completed: true });
    const payload = (updateChain.update as jest.Mock).mock.calls[0][0] as Record<string, unknown>;
    expect(payload.completed).toBe(true);
    // completed_at NOT in payload — DB retains original value
    expect('completed_at' in payload).toBe(false);
  });

  it('clears completed_at when completed toggled to false', async () => {
    // completed: false — no fetch-current call, goes straight to update (3 DB calls total)
    const updateChain = makeUpdateChain({ data: { ...MILESTONE_ROW, completed: false, completed_at: null }, error: null });
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(updateChain);

    await updateMilestone(MILESTONE_ID, USER_ID, { completed: false });
    const payload = (updateChain.update as jest.Mock).mock.calls[0][0] as Record<string, unknown>;
    expect(payload.completed).toBe(false);
    expect(payload.completed_at).toBeNull();
  });

  it('updates position field', async () => {
    const updateChain = makeUpdateChain({ data: { ...MILESTONE_ROW, position: 3 }, error: null });
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(updateChain);

    const result = await updateMilestone(MILESTONE_ID, USER_ID, { position: 3 });
    expect(result.position).toBe(3);
    expect(updateChain.update).toHaveBeenCalledWith(expect.objectContaining({ position: 3 }));
  });

  it('explicitly sets due_date to null via in-check', async () => {
    const updateChain = makeUpdateChain({ data: { ...MILESTONE_ROW, due_date: null }, error: null });
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(updateChain);

    await updateMilestone(MILESTONE_ID, USER_ID, { due_date: null });
    const payload = (updateChain.update as jest.Mock).mock.calls[0][0] as Record<string, unknown>;
    expect(payload.due_date).toBeNull();
  });

  it('throws VALIDATION_ERROR when no fields provided — no DB calls made', async () => {
    await expect(updateMilestone(MILESTONE_ID, USER_ID, {})).rejects.toMatchObject({
      code: ErrorCodes.VALIDATION_ERROR,
      statusCode: 400,
    });
    expect(mockFrom).not.toHaveBeenCalled();
  });

  it('throws NOT_FOUND when workspace has no projects', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(EMPTY_PROJECT_IDS_RESULT));

    await expect(updateMilestone(MILESTONE_ID, USER_ID, { title: 'X' })).rejects.toMatchObject({
      code: ErrorCodes.NOT_FOUND,
      statusCode: 404,
    });
  });

  it('throws NOT_FOUND when milestone does not exist or not owned (PGRST116)', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(makeUpdateChain({ data: null, error: { code: 'PGRST116' } }));

    await expect(updateMilestone(MILESTONE_ID, USER_ID, { title: 'X' })).rejects.toMatchObject({
      code: ErrorCodes.NOT_FOUND,
    });
  });

  it('throws DB_ERROR when data is null without error', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(makeUpdateChain({ data: null, error: null }));

    await expect(updateMilestone(MILESTONE_ID, USER_ID, { title: 'X' })).rejects.toMatchObject({
      code: ErrorCodes.DB_ERROR,
      statusCode: 500,
    });
  });
});

describe('deleteMilestone', () => {
  it('hard-deletes milestone without error', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(makeDeleteChain({ error: null, count: 1 }));

    await expect(deleteMilestone(MILESTONE_ID, USER_ID)).resolves.toBeUndefined();
  });

  it('throws NOT_FOUND when workspace has no projects', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(EMPTY_PROJECT_IDS_RESULT));

    await expect(deleteMilestone(MILESTONE_ID, USER_ID)).rejects.toMatchObject({
      code: ErrorCodes.NOT_FOUND,
      statusCode: 404,
    });
  });

  it('throws NOT_FOUND when count is 0', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(makeDeleteChain({ error: null, count: 0 }));

    await expect(deleteMilestone(MILESTONE_ID, USER_ID)).rejects.toMatchObject({ code: ErrorCodes.NOT_FOUND });
  });

  it('throws DB_ERROR when count is null — deletion unconfirmed', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(makeDeleteChain({ error: null, count: null }));

    await expect(deleteMilestone(MILESTONE_ID, USER_ID)).rejects.toMatchObject({
      code: ErrorCodes.DB_ERROR,
      statusCode: 500,
    });
  });

  it('throws DB_ERROR on delete query failure', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectIdsChain(PROJECT_IDS_RESULT))
      .mockReturnValueOnce(makeDeleteChain({ error: new Error('db down'), count: null }));

    await expect(deleteMilestone(MILESTONE_ID, USER_ID)).rejects.toMatchObject({ code: ErrorCodes.DB_ERROR });
  });
});
