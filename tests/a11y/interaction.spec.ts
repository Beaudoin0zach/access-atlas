import { test, expect } from '@playwright/test';

// UX-standard interaction guards (bas-platform/docs/design-principles.md §1, and
// this app's docs/ux/directory-ux.md §1.2 / §2.2). These are behaviours axe
// can't see, turned into mechanical checks so a refactor can't silently regress
// them (the "every invariant gets a check" discipline the a11y suite already
// follows).

// §2.2 — form controls must render at >= 16px. Below that, mobile Safari zooms
// the page when a field is focused, yanking the layout around. The floor lives
// in ONE rule (controls use `font: inherit` = the body's 1rem); this guards
// against a future style shrinking any field under it. Checked on every route
// that actually has inputs.
for (const route of ['/places/', '/settings/', '/contribute/submit/?kind=place']) {
  test(`form controls render at >= 16px (no iOS zoom-on-focus): ${route}`, async ({ page }) => {
    await page.goto(route);
    // Real text-entry / choice controls; checkboxes, radios and hidden inputs
    // don't get the auto-zoom treatment, so they're out of scope.
    const controls = page.locator(
      'input:not([type="checkbox"]):not([type="radio"]):not([type="hidden"]), select, textarea',
    );
    const count = await controls.count();
    expect(count).toBeGreaterThan(0); // the route is supposed to have inputs
    const sizesPx = await controls.evaluateAll((els) =>
      els.map((el) => parseFloat(getComputedStyle(el).fontSize)),
    );
    for (const px of sizesPx) expect(px).toBeGreaterThanOrEqual(16);
  });
}

// §1.2 — browser Back preserves place. Because the list's filter + sort state is
// entirely in the URL (a zero-JS GET form), a filtered list is its own history
// entry; going Back from a detail page must return to the SAME filtered, sorted
// list, not a bare/parent list. This is the behaviour most likely to break if
// someone ever moves the list into a client island, so it gets a guard.
test('browser Back restores the filtered list (URL query + result set preserved)', async ({
  page,
}) => {
  // A filter that matches seeded rows, PLUS a non-default sort — so we prove both
  // the query string and the re-rendered DOM come back intact.
  const listUrl = '/places/?county=Erie+County&sort=zip';
  await page.goto(listUrl);
  const before = await page.locator('ul.listing-list > li.listing-card').count();
  expect(before).toBeGreaterThan(0); // the filter must actually match something

  // Into a listing detail…
  await page.locator('ul.listing-list li.listing-card h3 a').first().click();
  await expect(page).toHaveURL(/\/places\/[0-9a-f-]+\/$/);

  // …and Back returns to the identical filtered, sorted list (server re-renders
  // the same URL; no client state to lose).
  await page.goBack();
  const back = new URL(page.url());
  expect(back.pathname).toBe('/places/');
  expect(back.search).toContain('county=Erie+County');
  expect(back.search).toContain('sort=zip');
  expect(await page.locator('ul.listing-list > li.listing-card').count()).toBe(before);
});
