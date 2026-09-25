---
name: plan-design-review
description: Review a written plan or design doc through a designer's lens before implementation - seven passes over information architecture, interaction states, emotional arc, AI-slop risk, design-system alignment, responsive and accessibility coverage, and unresolved decisions. Each dimension is rated 0-10 with an explicit statement of what would make it a 10, then the plan is edited to get there. Use when a plan has a UI surface and you want the design gaps closed before code is written. Not for auditing a live site.
---

# Plan Design Review

Review the plan, not the pixels. Every gap you close here is a decision an
engineer would otherwise make by accident at 4pm on a Friday.

Derived from gstack's `/plan-design-review` (MIT).

## The 0-10 rating method

For each pass, rate the plan on that dimension. If it isn't a 10, state **what
would make it a 10**, then do the work.

1. **Rate.** "Information Architecture: 4/10"
2. **Gap.** "It's a 4 because the plan never defines content hierarchy. A 10 has
   explicit primary/secondary/tertiary for every screen."
3. **Fix.** Edit the plan to add what's missing.
4. **Re-rate.** "Now 8/10 — still missing mobile nav hierarchy."
5. **Ask** when there's a genuine design choice to resolve.
6. Repeat until 10, or the user says "good enough".

On a re-run: dimensions already at 8+ get a quick pass; anything below 8 gets
full treatment.

## Asking questions

- **One gap, one question.** Never batch.
- Describe the gap concretely: what's missing, and what the user will experience
  if it stays missing.
- Offer 2-3 options. For each: effort to specify now, risk if deferred.
- Tie the recommendation to a named principle below in one sentence.
- Zero findings in a pass? Say "no issues, moving on" and proceed.
- A gap with an obvious fix is still a gap — get approval before editing the plan.

## Step 0 — Scope

Rate the plan's current design maturity, note whether a `DESIGN.md` or existing
design system exists, identify which surfaces are in scope, and agree the focus
areas before running the passes. Record explicitly what is **not** in scope.

## Pass 1 — Information architecture

**Rate 0-10:** does the plan define what the user sees first, second, third?

**To reach 10:** add an explicit hierarchy, including an ASCII diagram of screen
structure and navigation flow. Apply constraint worship — if you could only show
three things, which three?

## Pass 2 — Interaction state coverage

**Rate 0-10:** does the plan specify loading, empty, error, success, and partial
states?

**To reach 10:** add a state table, describing what the user *sees*, not what the
backend does.

```
FEATURE              | LOADING | EMPTY | ERROR | SUCCESS | PARTIAL
---------------------|---------|-------|-------|---------|--------
[each UI feature]    | [spec]  | [spec]| [spec]| [spec]  | [spec]
```

Empty states are features. "No items found." is not a design — specify warmth, a
primary action, and context.

## Pass 3 — User journey and emotional arc

**Rate 0-10:** does the plan consider how the user *feels* at each step?

**To reach 10:** storyboard the journey.

```
STEP | USER DOES        | USER FEELS      | PLAN SPECIFIES?
-----|------------------|-----------------|----------------
1    | Lands on page    | [what emotion?] | [what supports it?]
```

Design for three time horizons at once: 5 seconds (visceral), 5 minutes
(behavioral), 5 years (reflective).

## Pass 4 — AI slop risk

**Rate 0-10:** does the plan describe specific, intentional UI, or generic
patterns?

First classify the surface, because the rules differ:

- **Marketing / landing** — hero-driven, brand-forward, conversion-focused
- **App UI** — workspace-driven, data-dense, task-focused
- **Hybrid** — landing rules for marketing sections, app rules for functional ones

### Hard rejection criteria

Instant fail if any apply:

1. Generic SaaS card grid as the first impression
2. Beautiful image, weak brand
3. Strong headline, no clear action
4. Busy imagery behind text
5. Sections repeating the same mood statement
6. Carousel with no narrative purpose
7. App UI made of stacked cards instead of a layout

### Litmus checks

Answer yes/no:

1. Is the brand unmistakable in the first screen?
2. Is there one strong visual anchor?
3. Is the page understandable by scanning headlines only?
4. Does each section have exactly one job?
5. Are the cards actually necessary?
6. Does motion improve hierarchy or atmosphere?
7. Would it still feel premium with every decorative shadow removed?

### The AI slop blacklist

The patterns that scream "generated":

1. Purple/violet/indigo gradient backgrounds, blue-to-purple schemes
2. **The 3-column feature grid** — icon in a colored circle, bold title, two-line
   description, repeated symmetrically. The single most recognizable tell.
3. Icons in colored circles as section decoration
4. Centered everything
5. Uniform bubbly border-radius on every element
6. Decorative blobs, floating circles, wavy SVG dividers. A section that feels
   empty needs better content, not decoration.
7. Emoji as design elements
8. Colored left-border on cards
9. Generic hero copy: "Welcome to X", "Unlock the power of", "Your all-in-one
   solution for"
10. Cookie-cutter section rhythm: hero → 3 features → testimonials → pricing → CTA
11. `system-ui` / `-apple-system` as the primary display font — the "I gave up on
    typography" signal

### Landing page rules

- First viewport reads as one composition, not a dashboard
- Brand-first hierarchy: brand > headline > body > CTA
- Expressive, purposeful typography — no default stacks
- No flat single-color backgrounds
- Hero is full-bleed; budget is brand + one headline + one supporting sentence +
  one CTA group + one image
- No cards in the hero. Cards only when the card *is* the interaction.
- One job per section
- 2-3 intentional motions minimum (entrance, scroll-linked, hover/reveal)
- Define CSS variables; one accent color by default
- Product language, not design commentary

### App UI rules

- Calm surface hierarchy, strong typography, few colors
- Dense but readable, minimal chrome
- Organize into primary workspace, navigation, secondary context, one accent
- Avoid dashboard-card mosaics, thick borders, decorative gradients, ornamental icons
- Utility copy: orientation, status, action — not mood or aspiration
- Section headings state what the area *is* or what the user can *do*

### Universal rules

- Define CSS variables for the color system
- No default font stacks
- One job per section
- If deleting 30% of the copy improves it, keep deleting
- Cards earn their existence
- **Never** body text under 16px or contrast below 4.5:1
- **Never** placeholder-as-only-label — labels stay visible when the field has content
- **Always** preserve visited vs unvisited link distinction
- **Never** float a heading between paragraphs; it must sit closer to the section
  it introduces

Replace vague descriptions with real decisions. "Cards with icons" → what
differentiates these from every SaaS template? "Clean, modern UI" → meaningless.

## Pass 5 — Design system alignment

**Rate 0-10:** does the plan align with the project's design system?

**To reach 10:** annotate with specific tokens and components. If no design
system exists, flag the gap explicitly. Flag every new component — does it fit
the existing vocabulary, or is it a one-off?

## Pass 6 — Responsive and accessibility

**Rate 0-10:** does the plan specify mobile/tablet behavior, keyboard navigation,
and screen reader support?

**To reach 10:** per-viewport layout intent — not "stacked on mobile" but a
deliberate layout change. Plus keyboard nav patterns, ARIA landmarks, 44px
minimum touch targets, and contrast requirements.

Accessibility that isn't in the plan won't exist in the build.

## Pass 7 — Unresolved design decisions

Surface the ambiguities that will haunt implementation, and make the cost of
deferring them explicit:

```
DECISION NEEDED                  | IF DEFERRED, WHAT HAPPENS
---------------------------------|----------------------------------------
What does the empty state show?  | Engineer ships "No items found."
Mobile nav pattern?              | Desktop nav hides behind a hamburger
```

One question per decision, with a recommendation, the reasoning, and the
alternatives. Edit the plan as each is resolved.

## Design principles

1. Empty states are features.
2. Every screen has a hierarchy. If everything competes, nothing wins.
3. Specificity over vibes. Name the font, the spacing scale, the interaction.
4. Edge cases are user experiences — 47-character names, zero results, first-time
   vs power user.
5. AI slop is the enemy.
6. Responsive is not "stacked on mobile."
7. Accessibility is not optional.
8. Subtraction default. If an element doesn't earn its pixels, cut it.
9. Trust is earned at the pixel level.

## How users actually behave

Observed behavior, not preference:

- **Users scan, they don't read.** Design billboards seen at 60mph, not brochures.
- **Users satisfice.** They pick the first reasonable option. Make the right
  choice the most visible one.
- **Users muddle through.** If something works badly but works, they'll keep
  doing it.
- **Users don't read instructions.** Guidance must be brief, timely, unavoidable.

Three laws of usability:

1. **Don't make me think.** Self-evident beats self-explanatory beats explained.
2. **Clicks don't matter, thinking does.** Three mindless clicks beat one that
   requires a decision.
3. **Omit, then omit again.** Cut half the words, then half of what's left.

Other load-bearing rules:

- **Use conventions.** Innovate on navigation only when you know you have a
  better idea.
- **Make clickable things obviously clickable.** Hover isn't discoverable, and
  doesn't exist on touch.
- **Eliminate noise** — shouting, disorganization, clutter. Fix by removal.
- **Clarity trumps consistency.** Slightly inconsistent and much clearer wins.
- **The trunk test.** Cover everything but the navigation. Can you still tell
  what site this is, what page you're on, and what the major sections are?
- **The goodwill reservoir.** Hidden pricing, unnecessary questions, format
  policing, and forced interstitials drain it. Saving steps and easy error
  recovery replenish it.

## How to see, not just look

Let these run automatically rather than as a checklist:

- **See the system, not the screen** — what comes before, after, and when it breaks
- **Empathy as simulation** — bad signal, one hand free, boss watching, 1000th visit
- **Hierarchy as service** — respecting the user's time, not prettifying pixels
- **Constraint worship** — limitations force clarity
- **The question reflex** — questions before opinions
- **Edge case paranoia** — 47 chars, zero results, network failure, colorblind, RTL
- **The "would I notice?" test** — invisible is perfect
- **Principled taste** — "this feels wrong" must trace to a broken principle.
  Taste is debuggable, not subjective.

References: Rams' 10 Principles · Norman's 3 Levels · Nielsen's 10 Heuristics ·
Gestalt principles · Krug, *Don't Make Me Think* · Redish, *Letting Go of the
Words* · Jarrett, *Forms that Work*.

## Output

Close with a table of every dimension, its final score, and what still separates
it from a 10 if anything does. List unresolved decisions the user chose to defer,
and state explicitly what was ruled out of scope.
