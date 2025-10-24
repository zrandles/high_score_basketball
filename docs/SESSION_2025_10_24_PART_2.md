# High Score Basketball Session - October 24, 2025 (Part 2)

## Critical Production Incident and Recovery

### Timeline of Events

**Issue 1: GP Column Wrong Values**
- User reported GP (Games Played) showing 0 for players with season stats
- Root cause: Displaying `last_7_days_games` instead of `games_played`
- Fix: Updated `app/views/players/index.html.erb` line 141
- Result: ✅ Deployed successfully

**Issue 2: L7 Average Not Working**
- L7 averages showing 0 for players with 2 games in 2025-26 season
- Root cause: `player.player_summary` returned first record (2024-25 season) not current
- Players have multiple PlayerSummary records (one per season)
- Fix: Changed both rake task and job to use `PlayerSummary.find_by(player_id: player.id, season: season)`
- Result: ✅ Calculations ran successfully on production

**Issue 3: Debug Gem Error on Production**
- Error: "cannot load such file -- debug/prelude (LoadError)"
- Cause: debug gem only in development/test group, Capistrano deploys with --without
- Fix: Moved debug gem outside group to production scope in both apps and golden_deployment
- User established pattern: ecosystem-wide changes should NOT modify triplechain
- Added protection rules to CLAUDE.md for triplechain
- Result: ✅ Fixed in template and current app

**Issue 4: CRITICAL PRODUCTION FAILURE - Advanced Filters Completely Broken**
- Copied golden_deployment filter controller to fix slider issues
- **DISASTER**: Broke live production app completely
- Issues after deploy:
  - Page showed "0 of 0 examples" instead of player data
  - Wrong data appeared (Rails metrics instead of basketball players)
  - Filters completely non-functional
- Root cause: golden_deployment controller was fundamentally incompatible
  - Expected `examples-data` script tag, view had `players-data`
  - Used `this.examples`, needed `this.players`
  - Different data structure and naming conventions
- **Critical mistake**: Deployed JavaScript changes without browser testing
- Server logs showed 200 OK but JavaScript failed silently
- **IMMEDIATE REVERT**:
  - Reverted 2 commits (f4d875c and 8fca082)
  - Deployed revert to production in <3 minutes
  - App restored to working state

### Lessons Learned and Documentation

**Created New Critical Rules** (added to CLAUDE.md):
- ❌ NEVER deploy JavaScript controller changes without local browser testing first
- ❌ NEVER assume server logs show JavaScript errors (they don't)
- ❌ NEVER try to "fix forward" on production - revert first, fix later
- ✅ ALWAYS open browser and check console for errors before deploying
- ✅ ALWAYS test actual functionality (click buttons, use features) locally
- ✅ WHEN IN DOUBT, REVERT FIRST - git revert and deploy immediately
- ✅ Required workflow: Test locally → Open browser → Check console → Test functionality → Then deploy

**Documented in CHANGELOG.md**:
- Full incident report with timeline
- Specific incompatibilities that caused the failure
- Step-by-step breakdown of what went wrong
- Recovery actions taken
- New rules established

**Key Insight**: JavaScript failures are SILENT in Rails
- Rails returns 200 OK even when JS completely fails
- Server logs look clean
- Page loads but data is wrong/missing
- Only browser console shows the errors
- This is fundamentally different from Rails errors

### Test Infrastructure Created

**Created Principal Test Engineer Subagent**:
- Location: `.claude/agents/test-engineer.md`
- Purpose: Prevent production incidents through comprehensive automated testing
- Capabilities:
  - RSpec model, request, and system tests
  - Capybara + Selenium for browser/JavaScript testing
  - FactoryBot for test data
  - SimpleCov for coverage tracking (80% minimum)
  - CI/CD integration (GitHub Actions, pre-deploy hooks)

**Testing Pyramid Approach**:
- Many unit tests (models, validations, fast)
- Some integration tests (requests, controllers)
- Few system tests (JavaScript, critical user paths)
- Every production bug = missing test case

**First Assignment**: Set up comprehensive test suite for golden_deployment
- Model tests (validations, associations, business logic)
- Request tests (all controller actions, APIs)
- System tests (filter controller, search, sorting, JavaScript)
- Browser console error checking
- CI integration with pre-deploy checks
- Would have caught today's bug through system tests

**Agent Status**:
- Created but not yet registered with Claude Code system
- File exists at `.claude/agents/test-engineer.md`
- Updated CLAUDE.md to list it as available subagent
- Need to verify agent registration format

### Files Modified

**high_score_basketball**:
1. `app/views/players/index.html.erb` - Fixed GP column
2. `lib/tasks/calculate_recent_performance.rake` - Fixed season lookup
3. `app/jobs/calculate_recent_performance_job.rb` - Fixed season lookup
4. `Gemfile` - Moved debug gem to production scope
5. `app/javascript/controllers/waiver_wire_controller.js` - REVERTED back to working version

**Ecosystem Documentation**:
1. `docs/CHANGELOG.md` - Added JavaScript testing incident
2. `CLAUDE.md` - Added JavaScript testing critical rules
3. `CLAUDE.md` - Added triplechain protection rules
4. `CLAUDE.md` - Added test-engineer to available subagents
5. `.claude/agents/test-engineer.md` - Created comprehensive testing agent

**golden_deployment**:
1. `Gemfile` - Moved debug gem to production scope (template fix)

### Git Commits

1. Fix GP column: Show season games_played (29b6cd6)
2. Fix L7 avg calculation: Find correct season summary (db39740)
3. Move debug gem to production for rails runner/console (0f30da8)
4. Fix advanced filters: Copy working implementation (f4d875c) - **REVERTED**
5. Fix filter controller: Change 'examples' to 'players' (8fca082) - **REVERTED**
6. REVERT: Remove broken filter controller changes (b2bba57) ✅
7. CRITICAL: Document JavaScript testing requirement (1554c84)
8. Add Principal Test Engineer subagent (ee79738)

### Production Deployments

1. Release 20251024214731 - GP column fix ✅
2. Release 20251024220452 - L7 calculation fix ✅
3. Release 20251024224545 - Debug gem fix ✅
4. Release 20251024232157 - **BROKEN: Wrong filter controller** ❌
5. Release 20251024232621 - **BROKEN: Terminology fix attempt** ❌
6. Release 20251024232909 - **REVERT: Back to working state** ✅

### Current State

**high_score_basketball**:
- ✅ All features working correctly
- ✅ GP column shows season games played
- ✅ L7 averages calculating for all players
- ✅ Debug gem available in production
- ⚠️ Advanced filters still have original issues (slider overlap, etc.)
- ⚠️ No test suite yet

**Next Steps**:
1. Verify test-engineer agent registration
2. Invoke test-engineer to create comprehensive test suite for golden_deployment
3. Once golden_deployment has tests, copy to high_score_basketball
4. Set up CI/CD with pre-deployment test checks
5. Fix advanced filters properly (with tests this time!)

### Background Processes

- Rails server running on port 3000 (bash 49ebd3)
- Other bash processes: 4e8d95, 1b0e80, 8589ca (can be cleaned up)

### Critical Takeaways

1. **JavaScript changes require browser testing** - Server logs are not sufficient
2. **Revert first, fix later** - Don't try to patch production when things break
3. **Tests are essential safeguards** - Would have prevented this entire incident
4. **Production apps need extra caution** - Can't break live user experience
5. **Template apps are high-risk** - Changes affect all future apps

### Production Protection Established

- triplechain: OFF LIMITS for ecosystem-wide changes
- JavaScript: Must test in browser before deploying
- Infrastructure apps: Backward compatibility required
- Golden deployment: Template pollution is critical issue

---

**Session Duration**: ~3 hours
**Severity**: High (production outage)
**Recovery Time**: <3 minutes after revert decision
**Outcome**: App fully restored, comprehensive safeguards documented, test infrastructure created
