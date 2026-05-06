import { ErrorCodes } from '../errors/codes';
import { supabaseAdmin } from '../config/adminDb';

jest.mock('../config/adminDb', () => ({
  supabaseAdmin: { from: jest.fn(), rpc: jest.fn() },
}));

import {
  listProjects,
  getProject,
  createProject,
  updateProject,
  archiveProject,
  ProjectListItem,
} from '../services/project.service';

const mockFrom = supabaseAdmin.from as jest.Mock;
const mockRpc = supabaseAdmin.rpc as jest.Mock;

const USER_ID = 'user-1';
const WORKSPACE_ID = 'ws-1';
const PROJECT_ID = 'proj-1';

const WORKSPACE_ROW = { id: WORKSPACE_ID };
const PROJECT_ROW = {
  id: PROJECT_ID,
  workspace_id: WORKSPACE_ID,
  name: 'Alpha',
  description: null,
  client_name: 'Acme',
  client_email: 'client@acme.com',
  status: 'active' as const,
  share_token: 'tok123',
  start_date: null,
  expected_end_date: null,
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-01T00:00:00Z',
};

// getWorkspaceIdForUser: .select('id').eq('owner_id',v).is('deleted_at',null).limit(1)
// data is an array: [row] | []
function makeWsLimitChain(result: { data: unknown; error: unknown }) {
  const limitMock = jest.fn().mockResolvedValue(result);
  const isMock = jest.fn().mockReturnValue({ limit: limitMock });
  const eqMock = jest.fn().mockReturnValue({ is: isMock });
  const selectMock = jest.fn().mockReturnValue({ eq: eqMock });
  return { select: selectMock };
}

// getProject: .select(cols).eq('id',v).eq('workspace_id',v).is('deleted_at',null).single()
function makeProjectSelectChain(result: { data: unknown; error: unknown }) {
  const singleMock = jest.fn().mockResolvedValue(result);
  const isMock = jest.fn().mockReturnValue({ single: singleMock });
  const eq2Mock = jest.fn().mockReturnValue({ is: isMock });
  const eq1Mock = jest.fn().mockReturnValue({ eq: eq2Mock });
  const selectMock = jest.fn().mockReturnValue({ eq: eq1Mock });
  return { select: selectMock };
}

// createProject: .insert({}).select(cols).single()
function makeInsertChain(result: { data: unknown; error: unknown }) {
  const singleMock = jest.fn().mockResolvedValue(result);
  const selectMock = jest.fn().mockReturnValue({ single: singleMock });
  const insertMock = jest.fn().mockReturnValue({ select: selectMock });
  return { insert: insertMock };
}

// updateProject / archiveProject: .update({}).eq(k,v).eq(k,v).is(k,v).select(cols).single()
function makeUpdateChain(result: { data: unknown; error: unknown }) {
  const singleMock = jest.fn().mockResolvedValue(result);
  const selectMock = jest.fn().mockReturnValue({ single: singleMock });
  const isMock = jest.fn().mockReturnValue({ select: selectMock });
  const eq2Mock = jest.fn().mockReturnValue({ is: isMock });
  const eq1Mock = jest.fn().mockReturnValue({ eq: eq2Mock });
  const updateMock = jest.fn().mockReturnValue({ eq: eq1Mock });
  return { update: updateMock };
}

beforeEach(() => jest.clearAllMocks());

describe('listProjects', () => {
  // RPC returns rows already shaped as ProjectListItem (aggregates computed in SQL).
  // The service is now a thin pass-through, so tests verify wiring + error handling
  // rather than aggregation correctness (that lives in the SQL function).

  it('passes workspace id to RPC and returns rows verbatim', async () => {
    const ROW: ProjectListItem = {
      ...PROJECT_ROW,
      update_count: 5,
      comment_count: 3,
      latest_update_title: 'Homepage design ready',
      progress_pct: 60,
    };
    mockFrom.mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }));
    mockRpc.mockResolvedValueOnce({ data: [ROW], error: null });

    const result = await listProjects(USER_ID);
    expect(mockRpc).toHaveBeenCalledWith('list_projects_with_aggregates', {
      p_workspace_id: WORKSPACE_ID,
    });
    expect(result).toEqual([ROW]);
  });

  it('returns empty array when RPC returns null data', async () => {
    mockFrom.mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }));
    mockRpc.mockResolvedValueOnce({ data: null, error: null });

    const result = await listProjects(USER_ID);
    expect(result).toEqual([]);
  });

  it('returns empty array when RPC returns empty array', async () => {
    mockFrom.mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }));
    mockRpc.mockResolvedValueOnce({ data: [], error: null });

    const result = await listProjects(USER_ID);
    expect(result).toEqual([]);
  });

  it('throws NOT_FOUND 404 when user has no workspace (RPC not called)', async () => {
    mockFrom.mockReturnValueOnce(makeWsLimitChain({ data: [], error: null }));
    await expect(listProjects(USER_ID)).rejects.toMatchObject({
      code: ErrorCodes.NOT_FOUND,
      statusCode: 404,
    });
    expect(mockRpc).not.toHaveBeenCalled();
  });

  it('throws DB_ERROR 500 when workspace lookup fails (RPC not called)', async () => {
    mockFrom.mockReturnValueOnce(makeWsLimitChain({ data: null, error: new Error('db down') }));
    await expect(listProjects(USER_ID)).rejects.toMatchObject({
      code: ErrorCodes.DB_ERROR,
      statusCode: 500,
    });
    expect(mockRpc).not.toHaveBeenCalled();
  });

  it('throws DB_ERROR when RPC fails', async () => {
    mockFrom.mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }));
    mockRpc.mockResolvedValueOnce({ data: null, error: new Error('rpc broken') });

    await expect(listProjects(USER_ID)).rejects.toMatchObject({
      code: ErrorCodes.DB_ERROR,
      statusCode: 500,
    });
  });

  it('preserves NULL progress_pct from RPC (project with no milestones)', async () => {
    const ROW: ProjectListItem = {
      ...PROJECT_ROW,
      update_count: 0,
      comment_count: 0,
      latest_update_title: null,
      progress_pct: null,
    };
    mockFrom.mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }));
    mockRpc.mockResolvedValueOnce({ data: [ROW], error: null });

    const result = await listProjects(USER_ID);
    expect(result[0]?.progress_pct).toBeNull();
  });

  it('preserves zero progress_pct from RPC (milestones exist, none complete)', async () => {
    const ROW: ProjectListItem = {
      ...PROJECT_ROW,
      update_count: 0,
      comment_count: 0,
      latest_update_title: null,
      progress_pct: 0,
    };
    mockFrom.mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }));
    mockRpc.mockResolvedValueOnce({ data: [ROW], error: null });

    const result = await listProjects(USER_ID);
    expect(result[0]?.progress_pct).toBe(0);
  });
});

describe('getProject', () => {
  it('returns project when found and owned', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectSelectChain({ data: PROJECT_ROW, error: null }));

    const result = await getProject(PROJECT_ID, USER_ID);
    expect(result).toEqual(PROJECT_ROW);
  });

  it('throws NOT_FOUND when project belongs to different workspace', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeProjectSelectChain({ data: null, error: { code: 'PGRST116' } }));

    await expect(getProject(PROJECT_ID, USER_ID)).rejects.toMatchObject({ code: ErrorCodes.NOT_FOUND });
  });
});

describe('createProject', () => {
  const INPUT = { name: 'Beta', client_name: 'Globex', client_email: 'hi@globex.com' };

  it('inserts project and returns row', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeInsertChain({ data: PROJECT_ROW, error: null }));

    const result = await createProject(USER_ID, INPUT);
    expect(result).toEqual(PROJECT_ROW);
  });

  it('normalizes empty description to null', async () => {
    const insertChain = makeInsertChain({ data: PROJECT_ROW, error: null });
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(insertChain);

    await createProject(USER_ID, { ...INPUT, description: '   ' });
    expect(insertChain.insert).toHaveBeenCalledWith(
      expect.objectContaining({ description: null }),
    );
  });

  it('throws VALIDATION_ERROR on invalid email (23514 constraint)', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeInsertChain({ data: null, error: { code: '23514' } }));

    await expect(createProject(USER_ID, { ...INPUT, client_email: 'bad' })).rejects.toMatchObject({
      code: ErrorCodes.VALIDATION_ERROR,
      statusCode: 400,
    });
  });

  it('throws DB_ERROR on generic insert failure', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeInsertChain({ data: null, error: new Error('db down') }));

    await expect(createProject(USER_ID, INPUT)).rejects.toMatchObject({ code: ErrorCodes.DB_ERROR });
  });
});

describe('updateProject', () => {
  it('updates name and returns project', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeUpdateChain({ data: { ...PROJECT_ROW, name: 'Gamma' }, error: null }));

    const result = await updateProject(PROJECT_ID, USER_ID, { name: 'Gamma' });
    expect(result.name).toBe('Gamma');
  });

  it('throws VALIDATION_ERROR when no fields provided', async () => {
    mockFrom.mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }));

    await expect(updateProject(PROJECT_ID, USER_ID, {})).rejects.toMatchObject({
      code: ErrorCodes.VALIDATION_ERROR,
      statusCode: 400,
    });
  });

  it('throws VALIDATION_ERROR on invalid status before any DB call', async () => {
    await expect(
      updateProject(PROJECT_ID, USER_ID, { status: 'deleted' as 'active' }),
    ).rejects.toMatchObject({ code: ErrorCodes.VALIDATION_ERROR, statusCode: 400 });
    expect(mockFrom).not.toHaveBeenCalled();
  });

  it('throws NOT_FOUND when UPDATE matches no rows (PGRST116)', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeUpdateChain({ data: null, error: { code: 'PGRST116' } }));

    await expect(updateProject(PROJECT_ID, USER_ID, { name: 'X' })).rejects.toMatchObject({
      code: ErrorCodes.NOT_FOUND,
      statusCode: 404,
    });
  });

  it('throws VALIDATION_ERROR on email constraint violation (23514)', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeUpdateChain({ data: null, error: { code: '23514' } }));

    await expect(
      updateProject(PROJECT_ID, USER_ID, { client_email: 'bad-email' }),
    ).rejects.toMatchObject({ code: ErrorCodes.VALIDATION_ERROR });
  });
});

describe('archiveProject', () => {
  it('sets status to archived', async () => {
    const archived = { ...PROJECT_ROW, status: 'archived' };
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeUpdateChain({ data: archived, error: null }));

    const result = await archiveProject(PROJECT_ID, USER_ID);
    expect(result.status).toBe('archived');
  });

  it('throws NOT_FOUND when project does not exist (PGRST116)', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeUpdateChain({ data: null, error: { code: 'PGRST116' } }));

    await expect(archiveProject(PROJECT_ID, USER_ID)).rejects.toMatchObject({ code: ErrorCodes.NOT_FOUND });
  });

  it('issues only 2 DB calls (no pre-flight ownership SELECT)', async () => {
    mockFrom
      .mockReturnValueOnce(makeWsLimitChain({ data: [WORKSPACE_ROW], error: null }))
      .mockReturnValueOnce(makeUpdateChain({ data: { ...PROJECT_ROW, status: 'archived' }, error: null }));

    await archiveProject(PROJECT_ID, USER_ID);
    expect(mockFrom).toHaveBeenCalledTimes(2);
  });
});
