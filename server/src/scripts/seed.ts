/**
 * seed.ts - Populate ClientPulse with realistic sample data via the REST API.
 *
 * Usage:
 *   1. Start the dev server:  npm run dev
 *   2. In a separate terminal:  npx ts-node src/scripts/seed.ts
 *
 * What it creates:
 *   - 1 agency user + workspace  (or re-uses existing if email already registered)
 *   - 4 projects  (3 active, 1 completed)
 *   - 3-5 milestones per project  (mix of completed / upcoming)
 *   - 3-5 updates per project  (mix of draft / published, all categories)
 *   - 2-4 comments per published update
 *
 * The script is idempotent-ish: re-running it will create duplicate data.
 * For a clean slate, truncate the tables first.
 */

const API = process.env['SEED_API_URL'] ?? 'http://localhost:3000/api/v1';

// --- Test account --------------------------------------------------------
const TEST_USER = {
  email: 'demo@clientpulse.dev',
  password: 'DemoPass123!',
  name: 'Alex Rivera',
  workspaceName: 'Rivera Digital Studio',
};

// --- Helpers -------------------------------------------------------------

async function api(
  method: string,
  path: string,
  body?: Record<string, unknown>,
  token?: string,
): Promise<any> {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(`${API}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  const json: any = await res.json();
  if (!json.success) {
    if (json.error?.code === 'EMAIL_EXISTS' || json.error?.code === 'REGISTRATION_ERROR') {
      return { __alreadyExists: true };
    }
    throw new Error(`API ${method} ${path} failed: ${JSON.stringify(json.error)}`);
  }
  return json.data;
}

function daysFromNow(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() + n);
  return d.toISOString().slice(0, 10);
}

function daysAgo(n: number): string {
  return daysFromNow(-n);
}

// --- Types ---------------------------------------------------------------

interface MilestoneData {
  title: string;
  due_date: string;
  completed: boolean;
}

interface UpdateData {
  title: string;
  body: string;
  status: string;
  category: string;
}

interface CommentData {
  body: string;
  author_type: 'client' | 'agency';
  author_name?: string;
}

interface ProjectData {
  name: string;
  description: string;
  client_name: string;
  client_email: string;
  status: string;
  start_date: string;
  expected_end_date: string;
  milestones: MilestoneData[];
  updates: UpdateData[];
  comments: CommentData[];
}

// --- Seed Data -----------------------------------------------------------

const PROJECTS: ProjectData[] = [
  {
    name: 'Meridian Rebrand & Website',
    description:
      'Full rebrand for Meridian Financial - new visual identity, brand guidelines, and a 12-page responsive marketing website with CMS integration.',
    client_name: 'Sarah Chen',
    client_email: 'sarah.chen@meridianfinancial.com',
    status: 'active',
    start_date: daysAgo(30),
    expected_end_date: daysFromNow(45),
    milestones: [
      { title: 'Brand Discovery Workshop', due_date: daysAgo(25), completed: true },
      { title: 'Logo & Visual Identity Delivery', due_date: daysAgo(10), completed: true },
      { title: 'Brand Guidelines Document', due_date: daysAgo(3), completed: true },
      { title: 'Website Wireframes Approval', due_date: daysFromNow(5), completed: false },
      { title: 'Development Sprint 1 - Homepage + About', due_date: daysFromNow(20), completed: false },
      { title: 'Full Site Launch', due_date: daysFromNow(45), completed: false },
    ],
    updates: [
      {
        title: 'Kickoff Complete - Discovery Insights',
        body: '## Discovery Workshop Summary\n\nWe wrapped up the 2-hour discovery session with the Meridian team yesterday. Here are the key takeaways:\n\n### Brand Perception\n- Current brand feels "dated and corporate" - team wants to project **trust + modernity**\n- Competitors (Vanguard, Betterment) are reference points but Meridian wants warmer, more approachable\n\n### Target Audience Shifts\n- Moving from pure HNW to also targeting younger professionals (28-40)\n- Digital-first experience is critical\n\n### Color Direction\n- Moving away from navy/gold - exploring deep teal, warm white, accents of amber\n\nNext step: moodboard + 3 logo concepts by end of week.',
        status: 'published',
        category: 'progress',
      },
      {
        title: 'Logo Concepts - Round 1',
        body: '## Three Directions Presented\n\n### Concept A - "Compass"\nMinimalist compass mark with clean sans-serif wordmark. Conveys navigation and trust.\n\n### Concept B - "Horizon"\nAbstract horizon line with rising gradient. Modern and optimistic.\n\n### Concept C - "Keystone"\nGeometric keystone shape integrating the M letterform. Solid and architectural.\n\n**Client selected Concept B** with refinements:\n- Slightly bolder weight on the wordmark\n- Warmer gradient tones\n- Explore monogram version for favicon/app icon\n\nRevisions in progress - final logo delivery expected this Friday.',
        status: 'published',
        category: 'milestone',
      },
      {
        title: 'CMS Integration Needs Clarification',
        body: '## Blocker: CMS Platform Decision\n\nWe need the Meridian team to confirm their CMS preference before we begin development:\n\n1. **WordPress + Elementor** - familiar to their team, lower dev cost\n2. **Webflow** - better designer control, hosting included\n3. **Headless CMS (Strapi/Contentful)** + Next.js - maximum flexibility, higher dev effort\n\n### Impact\n- This decision affects the website architecture, hosting setup, and timeline\n- Delaying this by more than 1 week will push the Dev Sprint 1 milestone\n\n**Action needed:** Sarah to confirm CMS choice by EOD Friday.',
        status: 'published',
        category: 'input_needed',
      },
      {
        title: 'Wireframes - Work in Progress',
        body: '## Wireframe Progress Update\n\nCurrently working through the wireframes in Figma:\n\n- [x] Homepage - hero, features grid, testimonials, CTA\n- [x] About page - team section, timeline, values\n- [ ] Services page - service cards with expandable details\n- [ ] Contact page - form + office locations map\n- [ ] Blog listing + article template\n\nSharing the Figma link for early feedback. These are low-fidelity - focusing on layout and content hierarchy, not visual design.\n\n*Note: Visual design phase begins after wireframe approval.*',
        status: 'draft',
        category: 'progress',
      },
    ],
    comments: [
      { body: 'Love the direction from the discovery session! The teal + amber palette sounds perfect for what we are going for.', author_type: 'client', author_name: 'Sarah Chen' },
      { body: 'Thanks Sarah! We will have the moodboard ready by Thursday - I think you will really like where this is heading.', author_type: 'agency' },
      { body: 'Regarding the CMS - we had an internal discussion and are leaning towards Webflow. Can we schedule a quick call to discuss the tradeoffs?', author_type: 'client', author_name: 'Sarah Chen' },
      { body: 'Absolutely! I will send over a calendar invite for tomorrow at 2pm. Will prepare a comparison doc as well.', author_type: 'agency' },
    ],
  },
  {
    name: 'Bloom E-Commerce Platform',
    description:
      'Custom Shopify Plus build for Bloom Botanicals - product pages, subscription flow, loyalty program integration, and custom checkout experience.',
    client_name: 'Marcus Thompson',
    client_email: 'marcus@bloombotanicals.co',
    status: 'active',
    start_date: daysAgo(14),
    expected_end_date: daysFromNow(60),
    milestones: [
      { title: 'Shopify Plus Store Setup', due_date: daysAgo(7), completed: true },
      { title: 'Product Page Templates', due_date: daysFromNow(7), completed: false },
      { title: 'Subscription Flow (ReCharge)', due_date: daysFromNow(21), completed: false },
      { title: 'Loyalty Program Integration', due_date: daysFromNow(35), completed: false },
      { title: 'UAT & Launch', due_date: daysFromNow(55), completed: false },
    ],
    updates: [
      {
        title: 'Shopify Plus Environment Ready',
        body: '## Store Foundation Set Up\n\nThe Shopify Plus development store is configured and ready:\n\n- Theme architecture using Dawn 2.0 as base\n- Development, staging, and production environments\n- Git-based deployment via Shopify CLI\n- Basic product schema with metafields for ingredients, usage instructions\n- Staff accounts provisioned for the Bloom team\n\n### Product Data\nWe have imported the initial product catalog (47 SKUs). Marcus - please review the product data in the staging store and flag any corrections needed.',
        status: 'published',
        category: 'milestone',
      },
      {
        title: 'Product Page Design Direction',
        body: '## Product Page UX Research\n\nAnalyzed top-performing DTC botanical/skincare brands for product page patterns:\n\n### Key Patterns We Are Adopting\n1. **Ingredient spotlight** - hero section highlighting key botanical with illustration\n2. **Usage ritual** - step-by-step visual guide (not just text instructions)\n3. **Social proof strip** - UGC photos + review highlights above the fold\n4. **Subscription upsell** - inline comparison (one-time vs. subscribe & save)\n\n### Technical Notes\n- Using Shopify Liquid + Alpine.js for interactive elements\n- Custom metafield schema for ingredient data\n- Responsive images via Shopify image CDN with art direction\n\nDesign mockups attached - please review by Wednesday.',
        status: 'published',
        category: 'progress',
      },
      {
        title: 'Deliverable: Brand Style Integration',
        body: '## Theme Customization Delivered\n\nThe Shopify theme now reflects Bloom brand identity:\n\n- Custom color palette (sage green, cream, terracotta accents)\n- Typography: Cormorant Garamond (headings) + Work Sans (body)\n- Custom icon set for product categories (30 icons)\n- Responsive navigation with mega menu for collections\n\nStaging URL has been shared via email. Please review across desktop and mobile.',
        status: 'published',
        category: 'deliverable',
      },
      {
        title: 'ReCharge API Rate Limiting Issue',
        body: '## Blocker: Subscription Sync\n\nWe have hit a rate limiting issue with the ReCharge API during bulk product sync:\n\n- **Issue:** ReCharge limits to 40 requests/min on their Pro plan\n- **Impact:** Initial product sync for 47 SKUs takes ~15 minutes instead of seconds\n- **Workaround:** Implementing request queuing with exponential backoff\n\nThis will not affect the end-user experience but slows down our development iteration cycle. Working on a solution - no timeline impact expected.',
        status: 'published',
        category: 'blocker',
      },
      {
        title: 'Subscription Flow - Architecture Draft',
        body: '## Draft: Subscription Architecture\n\n*This is an internal draft - not yet shared with the client.*\n\n### Flow Overview\n1. Customer selects product then chooses one-time or subscription\n2. Subscription options: every 2, 4, or 8 weeks\n3. Checkout creates Shopify order + ReCharge subscription\n4. Customer portal: pause, skip, swap products, update payment\n\n### Open Questions\n- Should we allow mixed carts (subscription + one-time)?\n- Discount structure: 15% or 20% for subscribers?\n- Gift subscriptions in V1 or V2?\n\nNeed to finalize before starting development.',
        status: 'draft',
        category: 'progress',
      },
    ],
    comments: [
      { body: 'The product page mockups look incredible! One question - can we add a "pairs well with" section for cross-selling?', author_type: 'client', author_name: 'Marcus Thompson' },
      { body: 'Great idea! We can use Shopify product recommendations API combined with manual curation via metafields. I will add it to the wireframes.', author_type: 'agency' },
      { body: 'The staging site looks really polished. The mega menu is exactly what we envisioned. Small note - can we make the terracotta accent slightly warmer?', author_type: 'client', author_name: 'Marcus Thompson' },
    ],
  },
  {
    name: 'Apex Fitness App MVP',
    description:
      'React Native mobile app for Apex Fitness - workout tracking, nutrition logging, progress photos, and social features. Built with Expo + Supabase backend.',
    client_name: 'Jordan Whitley',
    client_email: 'jordan@apexfitness.io',
    status: 'completed',
    start_date: daysAgo(90),
    expected_end_date: daysAgo(5),
    milestones: [
      { title: 'UX Research & User Flows', due_date: daysAgo(80), completed: true },
      { title: 'UI Design System', due_date: daysAgo(65), completed: true },
      { title: 'Core Workout Tracker', due_date: daysAgo(45), completed: true },
      { title: 'Nutrition & Macro Logging', due_date: daysAgo(30), completed: true },
      { title: 'Social Feed & Progress Photos', due_date: daysAgo(15), completed: true },
      { title: 'Beta Testing & App Store Submission', due_date: daysAgo(5), completed: true },
    ],
    updates: [
      {
        title: 'App Store Approval - We Are Live!',
        body: '## Apex Fitness is Live on Both Stores!\n\nExciting news - the app has been approved and is now available:\n\n- **iOS App Store:** Approved after first review (no rejections!)\n- **Google Play Store:** Live within 2 hours of submission\n\n### Launch Metrics (First 48 Hours)\n- 342 downloads (organic + pre-registered users)\n- 4.8 average rating (12 reviews)\n- 0 crash reports\n- Average session: 4.2 minutes\n\n### What Is Next\n- Monitoring crash-free rate and performance metrics\n- Collecting user feedback for V1.1 planning\n- Social sharing features going live next week\n\nCongratulations to the entire Apex team - this has been a fantastic collaboration!',
        status: 'published',
        category: 'milestone',
      },
      {
        title: 'Final QA Report - All Clear',
        body: '## QA Summary\n\nCompleted full regression testing across:\n- iPhone 15 Pro, iPhone SE (3rd gen), iPad Air\n- Samsung Galaxy S24, Pixel 8, OnePlus 12\n\n### Results\n| Area | Tests | Pass | Fail |\n|------|-------|------|------|\n| Auth & Onboarding | 24 | 24 | 0 |\n| Workout Tracking | 38 | 38 | 0 |\n| Nutrition Logging | 31 | 31 | 0 |\n| Progress Photos | 18 | 18 | 0 |\n| Social Feed | 22 | 22 | 0 |\n| Performance | 12 | 12 | 0 |\n\n**Total: 145/145 tests passing.** No critical or major bugs remaining.\n\nMinor items deferred to V1.1:\n- Dark mode calendar picker has slight contrast issue on Android 13\n- Nutrition search could be snappier with local caching (optimization)',
        status: 'published',
        category: 'deliverable',
      },
      {
        title: 'Social Feed Performance Optimization',
        body: '## Performance Improvements\n\nThe social feed was showing jank on older devices (Pixel 5, iPhone 11). We have made the following optimizations:\n\n1. **Image lazy loading** - progressive JPEG with blurhash placeholders\n2. **Virtualized list** - only renders visible items + 3 buffer\n3. **Cached API responses** - feed data cached for 5 minutes\n4. **Optimized re-renders** - memoized components, stable callbacks\n\n### Results\n- Feed scroll FPS: 42fps to 58fps on Pixel 5\n- Initial load: 2.8s to 1.1s\n- Memory usage: -35% during extended scrolling\n\nAll changes are in the latest beta build (v0.9.4-beta.2).',
        status: 'published',
        category: 'progress',
      },
    ],
    comments: [
      { body: 'Incredible launch numbers! Our marketing team is thrilled. Let us schedule a V1.1 planning session for next week.', author_type: 'client', author_name: 'Jordan Whitley' },
      { body: 'Would love that! I will prepare a prioritized feature backlog based on the early user feedback we are seeing.', author_type: 'agency' },
    ],
  },
  {
    name: 'Castellano Restaurant Group - Digital Menu',
    description:
      'Interactive digital menu system for 3 restaurant locations - QR-code accessible, multi-language support, real-time 86d item management, and allergen filtering.',
    client_name: 'Isabella Castellano',
    client_email: 'isabella@castellanogroup.com',
    status: 'active',
    start_date: daysAgo(7),
    expected_end_date: daysFromNow(28),
    milestones: [
      { title: 'Menu Data Architecture', due_date: daysAgo(3), completed: true },
      { title: 'Multi-Language Content Setup', due_date: daysFromNow(3), completed: false },
      { title: 'QR Code System & Landing Pages', due_date: daysFromNow(10), completed: false },
      { title: 'Real-Time 86 Dashboard', due_date: daysFromNow(18), completed: false },
      { title: 'Pilot Launch - Castellano Downtown', due_date: daysFromNow(25), completed: false },
    ],
    updates: [
      {
        title: 'Menu Data Schema Finalized',
        body: '## Database Architecture Complete\n\nThe menu data model is designed and implemented:\n\n### Schema Highlights\n- **Locations** > **Menus** > **Sections** > **Items** hierarchy\n- Each item supports:\n  - Multi-language names & descriptions (EN, ES, IT)\n  - Allergen tags (14 major allergens)\n  - Dietary flags (vegan, GF, dairy-free)\n  - Real-time availability toggle (86 system)\n  - Price variants (small/regular/large, lunch/dinner)\n\n### Data Import\n- Imported menu data for all 3 locations from the Excel sheets Isabella provided\n- **197 items** across 23 sections\n- Flagged 12 items with missing allergen data - need Isabella team to verify\n\nNext: multi-language translations and QR code generation.',
        status: 'published',
        category: 'milestone',
      },
      {
        title: 'Missing Allergen Data for 12 Items',
        body: '## Input Needed: Allergen Verification\n\nThe following items are missing allergen information in the source data:\n\n### Castellano Downtown\n1. Truffle Burrata - contains nuts?\n2. Seafood Risotto - which shellfish species?\n3. House-Made Pasta (all 4 variants) - egg-free option?\n\n### Castellano Waterfront\n4. Lobster Thermidor - dairy/mustard content?\n5. Charred Octopus - any marinades with soy?\n\n### Castellano Garden\n6-12. Seven seasonal specials - full allergen profiles needed\n\n**This is a compliance requirement** - we cannot launch without complete allergen data for all menu items.\n\nIsabella - can your kitchen managers fill in the attached spreadsheet by end of week?',
        status: 'published',
        category: 'input_needed',
      },
      {
        title: 'QR Code Design Concepts',
        body: '## QR Code Integration Approach\n\n*Draft - internal review before sharing with client.*\n\n### Two Approaches Under Consideration\n\n**Option A: Branded QR Codes**\n- Custom QR codes with Castellano logo embedded\n- Printed on table tents with short URL fallback\n- Pro: on-brand, premium feel\n- Con: slightly lower scan reliability\n\n**Option B: Standard QR + Branded Landing**\n- Standard high-contrast QR codes\n- Branded landing page with location auto-detection\n- Pro: 100% scan reliability, faster load\n- Con: QR itself is less visually distinctive\n\nLeaning towards Option B for reliability. Will prototype both for client review.',
        status: 'draft',
        category: 'progress',
      },
    ],
    comments: [
      { body: 'The schema looks great. I will have the kitchen managers fill out the allergen spreadsheet by Thursday. Can you send me the template?', author_type: 'client', author_name: 'Isabella Castellano' },
      { body: 'Just sent it to your email! It is a simple spreadsheet - one row per item, checkboxes for each allergen. Should take about 30 minutes per location.', author_type: 'agency' },
    ],
  },
];

// --- Main ----------------------------------------------------------------

async function main() {
  console.log('ClientPulse Seed Script');
  console.log('-'.repeat(50));

  // 1. Register or login
  console.log('\nRegistering test user...');
  const registerResult = await api('POST', '/auth/register', {
    email: TEST_USER.email,
    password: TEST_USER.password,
    name: TEST_USER.name,
    workspaceName: TEST_USER.workspaceName,
  });

  let token: string;
  if (registerResult.__alreadyExists) {
    console.log('   User already exists - logging in instead...');
  }

  console.log('Logging in...');
  const loginResult = await api('POST', '/auth/login', {
    email: TEST_USER.email,
    password: TEST_USER.password,
  });
  token = loginResult.token;
  console.log(`   Logged in as ${loginResult.user.name} (${loginResult.user.email})`);
  console.log(`   Workspace: ${loginResult.user.workspaceId}`);

  // 2. Create projects
  console.log('\nCreating projects...');
  for (const proj of PROJECTS) {
    const { milestones, updates, comments, status, ...projectData } = proj;

    const projectResult = await api('POST', '/projects', projectData, token);
    const projectId = projectResult.project.id;
    console.log(`   [OK] ${proj.name} -> ${projectId}`);

    // Update status if not 'active' (default)
    if (status !== 'active') {
      await api('PATCH', `/projects/${projectId}`, { status }, token);
      console.log(`      Status -> ${status}`);
    }

    // 3. Create milestones
    console.log('   Milestones:');
    for (let i = 0; i < milestones.length; i++) {
      const ms = milestones[i];
      const msResult = await api(
        'POST',
        `/projects/${projectId}/milestones`,
        { title: ms.title, due_date: ms.due_date, position: i },
        token,
      );
      const msId = msResult.milestone.id;

      if (ms.completed) {
        await api('PATCH', `/milestones/${msId}`, { completed: true }, token);
      }
      console.log(`      ${ms.completed ? '[x]' : '[ ]'} ${ms.title}`);
    }

    // 4. Create updates
    console.log('   Updates:');
    const publishedUpdateIds: string[] = [];
    for (const upd of updates) {
      const updateResult = await api(
        'POST',
        `/projects/${projectId}/updates`,
        { title: upd.title, body: upd.body, status: upd.status, category: upd.category },
        token,
      );
      const updateId = updateResult.update.id;
      if (upd.status === 'published') {
        publishedUpdateIds.push(updateId);
      }
      console.log(`      ${upd.status === 'published' ? '[pub]' : '[dft]'} [${upd.category}] ${upd.title}`);
    }

    // 5. Create comments on the first published update
    if (comments && comments.length > 0 && publishedUpdateIds.length > 0) {
      const targetUpdateId = publishedUpdateIds[0];
      console.log('   Comments:');
      let firstCommentId: string | undefined;
      for (let i = 0; i < comments.length; i++) {
        const c = comments[i];
        if (c.author_type === 'agency') {
          const commentResult = await api(
            'POST',
            `/updates/${targetUpdateId}/comments`,
            {
              body: c.body,
              parent_id: firstCommentId ?? undefined,
            },
            token,
          );
          if (i === 0) firstCommentId = commentResult.comment.id;
          console.log(`      [agency] ${loginResult.user.name}: "${c.body.slice(0, 50)}..."`);
        } else {
          const commentResult = await api(
            'POST',
            `/updates/${targetUpdateId}/comments`,
            {
              body: `[Client: ${c.author_name}] ${c.body}`,
              parent_id: firstCommentId ?? undefined,
            },
            token,
          );
          if (i === 0) firstCommentId = commentResult.comment.id;
          console.log(`      [client] ${c.author_name}: "${c.body.slice(0, 50)}..."`);
        }
      }
    }

    console.log('');
  }

  // --- Summary ---------------------------------------------------------
  console.log('-'.repeat(50));
  console.log('Seed complete!\n');
  console.log('Login credentials:');
  console.log(`   Email:    ${TEST_USER.email}`);
  console.log(`   Password: ${TEST_USER.password}`);
  console.log('');
  console.log('Projects created:');
  for (const p of PROJECTS) {
    const statusTag = p.status === 'active' ? '[active]' : p.status === 'completed' ? '[done]' : '[archived]';
    console.log(`   ${statusTag} ${p.name}`);
    console.log(`      Client: ${p.client_name} <${p.client_email}>`);
    console.log(`      Milestones: ${p.milestones.length} | Updates: ${p.updates.length}`);
  }
}

main().catch((err) => {
  console.error('\nSeed failed:', err.message);
  process.exit(1);
});
