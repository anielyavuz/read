export type MessageContext =
  | "daily_reminder"
  | "streak_risk"
  | "streak_lost"
  | "welcome_back"
  | "milestone"
  | "daily_goal"
  | "weekly_summary";

interface MessageTemplate {
  title: string;
  body: string;
}

type BreedMessages = Partial<Record<MessageContext, ((name: string, streakDays?: number) => MessageTemplate)[]>>;

const breedTemplates: Record<string, BreedMessages> = {
  golden_retriever: {
    daily_reminder: [
      (name) => ({
        title: `${name} misses you!`,
        body: `Your Golden is sitting by the bookshelf waiting for you. Just 10 minutes of reading would make ${name}'s day!`,
      }),
      (name) => ({
        title: `${name}'s tail is wagging!`,
        body: `Reading time is almost here! ${name} already picked out a cozy spot for both of you.`,
      }),
      (name) => ({
        title: `${name} brought your book!`,
        body: `${name} fetched your book and dropped it at your feet. Those big puppy eyes are impossible to resist!`,
      }),
      (name) => ({
        title: `Storytime with ${name}?`,
        body: `${name} is curled up on the couch, saving your favorite spot. All that's missing is you and a good book!`,
      }),
    ],
    streak_risk: [
      (name, streak) => ({
        title: `${name} is worried about you!`,
        body: `Your ${streak}-day streak is in danger! ${name} has been pacing by the door all day. Just one page, please?`,
      }),
      (name, streak) => ({
        title: `Don't break ${name}'s heart!`,
        body: `${name} has loyally read with you for ${streak} days straight. Don't let today be the day the streak ends!`,
      }),
      (name, streak) => ({
        title: `${name} is giving you puppy eyes`,
        body: `${streak} days together and counting... but not for long if you don't read today! ${name} believes in you.`,
      }),
    ],
    streak_lost: [
      (name) => ({
        title: `${name} is heartbroken`,
        body: `The streak is gone... but ${name} hasn't given up on you. Come back and start a new adventure together!`,
      }),
      (name) => ({
        title: `${name} saved your spot`,
        body: `Even though the streak broke, ${name} kept your bookmark safe. Ready to start fresh?`,
      }),
      (name) => ({
        title: `${name} is waiting patiently`,
        body: `Streaks come and go, but ${name}'s loyalty is forever. Let's build a new one together!`,
      }),
    ],
    welcome_back: [
      (name) => ({
        title: `${name} is SO happy you're back!`,
        body: `${name} hasn't stopped wagging since you opened the app! Let's read something wonderful together.`,
      }),
      (name) => ({
        title: `${name} never forgot you!`,
        body: `Your Golden has been guarding your bookshelf this whole time. Welcome home, reader!`,
      }),
      (name) => ({
        title: `Look who's back!`,
        body: `${name} just did three happy spins! The bookshelf is dusted and ready. Let's go!`,
      }),
    ],
    milestone: [
      (name) => ({
        title: `${name} is bursting with pride!`,
        body: `You did it! ${name} is doing the happiest zoomies right now. What an incredible milestone!`,
      }),
      (name) => ({
        title: `${name} wants to celebrate!`,
        body: `Amazing achievement! ${name} brought you a golden trophy (okay, it's a tennis ball, but the love is real).`,
      }),
      (name) => ({
        title: `You made ${name}'s day!`,
        body: `${name} is howling with joy at your achievement! The whole neighborhood knows how proud your Golden is.`,
      }),
    ],
  },

  corgi: {
    daily_reminder: [
      (name) => ({
        title: `${name} is zooming around!`,
        body: `Your Corgi is doing laps around the bookshelf! Quick reading sprint? 15 minutes is all ${name} asks!`,
      }),
      (name) => ({
        title: `Sprint time with ${name}!`,
        body: `${name} challenges you to a speed-reading sprint! Short legs, big energy. Let's gooo!`,
      }),
      (name) => ({
        title: `${name} can't sit still!`,
        body: `Too much energy, not enough pages! ${name} needs you to channel this into a reading burst. Ready, set, READ!`,
      }),
      (name) => ({
        title: `Quick quick quick!`,
        body: `${name} says even a short chapter counts! Corgis know that small bursts lead to big results.`,
      }),
    ],
    streak_risk: [
      (name, streak) => ({
        title: `${name} is doing panic zoomies!`,
        body: `${streak}-day streak about to vanish! ${name} is sprinting in circles. Just a quick page to calm this Corgi down!`,
      }),
      (name, streak) => ({
        title: `EMERGENCY SPRINT NEEDED!`,
        body: `${name} is sounding the alarm! ${streak} days of work about to disappear! Quick, read something, ANYTHING!`,
      }),
      (name, streak) => ({
        title: `${name} tripped over the urgency!`,
        body: `Those tiny legs are running as fast as they can to remind you: ${streak}-day streak needs saving! One page sprint, GO!`,
      }),
    ],
    streak_lost: [
      (name) => ({
        title: `${name} fell over in shock`,
        body: `The streak... it's gone. But ${name} is already back on those tiny feet. New sprint starts NOW!`,
      }),
      (name) => ({
        title: `${name} dusted off and is ready!`,
        body: `Corgis don't dwell on the past! ${name} is already at the starting line for a new streak sprint.`,
      }),
      (name) => ({
        title: `Reset? No problem!`,
        body: `${name} says every champion falls sometimes. What matters is the next sprint. Let's GO!`,
      }),
    ],
    welcome_back: [
      (name) => ({
        title: `${name} just did a backflip!`,
        body: `Okay, Corgis can't actually backflip, but ${name} TRIED because you're back! Let's sprint through some pages!`,
      }),
      (name) => ({
        title: `ZOOMIES ACTIVATED!`,
        body: `${name} is doing victory laps! You're back and it's time for the fastest reading sprint ever!`,
      }),
      (name) => ({
        title: `${name} has been WAITING!`,
        body: `All that pent-up energy is about to explode! ${name} needs a reading sprint with you RIGHT NOW.`,
      }),
    ],
    milestone: [
      (name) => ({
        title: `${name} is doing champion zoomies!`,
        body: `INCREDIBLE! ${name}'s little legs are a blur of celebration! You absolutely crushed that milestone!`,
      }),
      (name) => ({
        title: `Sprint champion!`,
        body: `${name} officially crowns you the Sprint Champion! Those tiny paws are clapping as fast as they can!`,
      }),
      (name) => ({
        title: `${name} can't believe it!`,
        body: `You hit that milestone at RECORD speed! ${name} is vibrating with excitement. What a team!`,
      }),
    ],
  },

  shiba_inu: {
    daily_reminder: [
      (name) => ({
        title: `${name} ponders...`,
        body: `"In the silence between pages, we find ourselves." ${name} has saved you a quiet corner for reflection.`,
      }),
      (name) => ({
        title: `A thought from ${name}`,
        body: `${name} stares out the window philosophically. Perhaps today's chapter holds the answer to life's questions.`,
      }),
      (name) => ({
        title: `${name} awaits, quietly`,
        body: `Your Shiba sits in perfect stillness. The book awaits. No rush, but the universe tends to reward those who read.`,
      }),
      (name) => ({
        title: `${name} left you a note`,
        body: `"The best time to read was yesterday. The second best time is now." - ${name}, philosopher & good boy`,
      }),
    ],
    streak_risk: [
      (name, streak) => ({
        title: `${name} raises one eyebrow`,
        body: `${streak} days of discipline, possibly ending today. ${name} won't judge... but ${name} will remember.`,
      }),
      (name, streak) => ({
        title: `${name} contemplates impermanence`,
        body: `All streaks must end eventually. But must yours end at ${streak} days? ${name} thinks not. One page changes everything.`,
      }),
      (name, streak) => ({
        title: `A quiet observation from ${name}`,
        body: `${name} noticed you haven't read today. ${streak} days is impressive. ${streak} + 1 would be... meaningful.`,
      }),
    ],
    streak_lost: [
      (name) => ({
        title: `${name} nods knowingly`,
        body: `The streak has ended. ${name} sits in quiet acceptance. Every ending is a new beginning, after all.`,
      }),
      (name) => ({
        title: `${name} has a new perspective`,
        body: `"A streak lost is wisdom gained." ${name} is ready for the next chapter, literally and metaphorically.`,
      }),
      (name) => ({
        title: `Such is life, says ${name}`,
        body: `The streak faded like cherry blossoms in spring. Beautiful while it lasted. ${name} awaits the next bloom.`,
      }),
    ],
    welcome_back: [
      (name) => ({
        title: `${name} acknowledges your return`,
        body: `A subtle tail wag. A knowing glance. ${name} has been waiting with the patience only a Shiba possesses.`,
      }),
      (name) => ({
        title: `${name} smirks`,
        body: `"I knew you'd come back." ${name} didn't worry for a second. Your Shiba had faith all along.`,
      }),
      (name) => ({
        title: `The prodigal reader returns`,
        body: `${name} tilts head slightly. Welcome back. The books haven't moved. Neither has ${name}.`,
      }),
    ],
    milestone: [
      (name) => ({
        title: `${name} is... impressed`,
        body: `That's the closest to excitement you'll ever see from ${name}. A slow blink of deep respect. Well done.`,
      }),
      (name) => ({
        title: `${name} offers a rare compliment`,
        body: `"Not bad, human. Not bad at all." For a Shiba, that's basically a standing ovation. Remarkable milestone.`,
      }),
      (name) => ({
        title: `Even ${name} is moved`,
        body: `A single, dignified tail wag. From your Shiba, that means more than a thousand words. Incredible achievement.`,
      }),
    ],
  },

  poodle: {
    daily_reminder: [
      (name) => ({
        title: `${name} has a question for you!`,
        body: `"Did you know the average person reads 12 books a year?" ${name} thinks you can do better. Reading time!`,
      }),
      (name) => ({
        title: `${name} prepared a study session`,
        body: `Your Poodle has organized your bookmarks, adjusted the reading light, and brewed metaphorical tea. Time to learn!`,
      }),
      (name) => ({
        title: `Intellectual hour with ${name}!`,
        body: `${name} is curious what happens in the next chapter. Your Poodle has been analyzing the plot all day!`,
      }),
      (name) => ({
        title: `${name} found something fascinating!`,
        body: `"Every page is a new discovery!" ${name} is practically vibrating with curiosity. Shall we investigate together?`,
      }),
    ],
    streak_risk: [
      (name, streak) => ({
        title: `${name} ran the numbers...`,
        body: `Statistically, breaking a ${streak}-day streak reduces future reading by 40%. ${name} made that up, but it FEELS true. Read!`,
      }),
      (name, streak) => ({
        title: `${name}'s analysis: URGENT`,
        body: `After careful calculation, ${name} concludes that your ${streak}-day streak has exactly 4 hours to survive. Data says: read now.`,
      }),
      (name, streak) => ({
        title: `${name} wrote you a thesis`,
        body: `Title: "Why ${streak} Days Should Become ${streak! + 1}: A Compelling Argument." TL;DR: Read one page. Please.`,
      }),
    ],
    streak_lost: [
      (name) => ({
        title: `${name} is recalculating...`,
        body: `Streak terminated. ${name} has already drafted a 12-step recovery plan. Step 1: Open a book. Shall we begin?`,
      }),
      (name) => ({
        title: `${name} found a silver lining`,
        body: `Analysis complete: streak lost, but knowledge gained remains at 100%. ${name} calls that a net positive. New streak?`,
      }),
      (name) => ({
        title: `Research shows...`,
        body: `${name} found that 94% of successful readers have broken a streak before. You're in excellent company. Start again!`,
      }),
    ],
    welcome_back: [
      (name) => ({
        title: `${name} has SO many questions!`,
        body: `Where were you? What did you learn? Never mind, ${name} has bookmarked 3 chapters for you to explore. Welcome back!`,
      }),
      (name) => ({
        title: `${name} updated your reading list!`,
        body: `While you were away, ${name} curated the perfect comeback reading plan. Intellectual adventure awaits!`,
      }),
      (name) => ({
        title: `Fascinating - you're back!`,
        body: `${name} has been taking notes in your absence. There's so much to discuss! Let's dive into those pages.`,
      }),
    ],
    milestone: [
      (name) => ({
        title: `${name}'s research confirms: YOU'RE AMAZING`,
        body: `After thorough analysis, ${name} has concluded that this milestone puts you in the top tier of readers. Scientifically impressive!`,
      }),
      (name) => ({
        title: `${name} is publishing the results!`,
        body: `"Subject demonstrated exceptional reading capability." ${name}'s peer review: 10/10. Outstanding milestone!`,
      }),
      (name) => ({
        title: `Eureka! says ${name}`,
        body: `${name} always hypothesized you'd reach this milestone. Hypothesis: confirmed! What a brilliant achievement.`,
      }),
    ],
  },

  dalmatian: {
    daily_reminder: [
      (name) => ({
        title: `${name} challenges you!`,
        body: `Think you can beat yesterday's page count? ${name} is keeping score. No pressure... but also ALL the pressure.`,
      }),
      (name) => ({
        title: `${name} spotted a challenge!`,
        body: `Your Dalmatian dares you to read more than you did last time. ${name} doesn't believe in "good enough."`,
      }),
      (name) => ({
        title: `Game on, says ${name}!`,
        body: `${name} set up the reading arena. Your competitors are reading RIGHT NOW. Are you going to let them win?`,
      }),
      (name) => ({
        title: `${name} raised the bar!`,
        body: `Yesterday was great, but ${name} wants LEGENDARY. Time to read and show the leaderboard who's boss!`,
      }),
    ],
    streak_risk: [
      (name, streak) => ({
        title: `${name} REFUSES to lose!`,
        body: `A ${streak}-day streak is on the line and ${name} will NOT accept defeat! Get in there and read! This is a competition!`,
      }),
      (name, streak) => ({
        title: `${name} is fired up!`,
        body: `Quitters lose streaks. Champions don't. ${name} knows which one you are. ${streak} days - don't throw it away!`,
      }),
      (name, streak) => ({
        title: `${name} won't let you give up!`,
        body: `${streak} days of WINNING and you're going to stop now?! ${name} is literally standing on your book. READ IT.`,
      }),
    ],
    streak_lost: [
      (name) => ({
        title: `${name} demands a rematch!`,
        body: `Streak lost? That's just fuel for the comeback! ${name} is already planning your redemption arc. Let's GO!`,
      }),
      (name) => ({
        title: `${name} is NOT done!`,
        body: `Every champion has a setback. ${name} says this is your origin story moment. New streak, bigger, better, NOW.`,
      }),
      (name) => ({
        title: `${name} smells a comeback!`,
        body: `The old streak is history. ${name} is ready for the NEW streak that's going to be even more legendary. Start today!`,
      }),
    ],
    welcome_back: [
      (name) => ({
        title: `${name} has been WAITING for this!`,
        body: `The competition missed you! ${name} is fired up and ready to dominate the leaderboard together. Game ON!`,
      }),
      (name) => ({
        title: `${name} spotted the champion!`,
        body: `You're BACK! ${name} has been training and is ready to crush some reading goals with you. No more holding back!`,
      }),
      (name) => ({
        title: `The challenger returns!`,
        body: `${name} just howled in excitement! The leaderboard trembles. Welcome back, champion. Let's compete!`,
      }),
    ],
    milestone: [
      (name) => ({
        title: `${name} is UNSTOPPABLE with you!`,
        body: `MILESTONE CRUSHED! ${name} is doing a victory lap with 101 spots of pride! You're a true champion!`,
      }),
      (name) => ({
        title: `WINNER WINNER! says ${name}`,
        body: `${name} always knew you were a competitor. This milestone PROVES it. Now let's aim even higher!`,
      }),
      (name) => ({
        title: `${name} calls it: LEGEND!`,
        body: `That milestone? Absolutely dominated. ${name} is adding another trophy to your shelf. What's the next target?`,
      }),
    ],
  },

  siberian_husky: {
    daily_reminder: [
      (name) => ({
        title: `${name} is HOWLING for you!`,
        body: `AWOOOO! ${name} has been singing the song of reading all day! The neighbors are concerned. Please read to calm this Husky!`,
      }),
      (name) => ({
        title: `${name} is being SO dramatic!`,
        body: `${name} has flopped on the floor and is making the most heartbreaking sounds. Only reading can fix this level of drama!`,
      }),
      (name) => ({
        title: `THE WORLD IS ENDING (says ${name})`,
        body: `${name} just knocked over the lamp in despair because you haven't read yet! Everything is chaos! Only a book can restore order!`,
      }),
      (name) => ({
        title: `${name} wrote you a soap opera`,
        body: `Episode 1: Human forgets to read. Episode 2: Husky's heart shatters into a million pieces. Episode 3: Human opens book. THE END.`,
      }),
      (name) => ({
        title: `${name} is staging a protest!`,
        body: `Your Husky is lying dramatically in front of the bookshelf, blocking it until you agree to read. ${name} plays hardball.`,
      }),
    ],
    streak_risk: [
      (name, streak) => ({
        title: `${name} is DEVASTATED`,
        body: `Your ${streak}-day streak is about to end! ${name} has been dramatically crying ALL DAY. Just one page to save everything!`,
      }),
      (name, streak) => ({
        title: `THIS IS NOT A DRILL!`,
        body: `${name} is having a full emotional breakdown! ${streak} DAYS about to vanish! The howling can be heard from SPACE!`,
      }),
      (name, streak) => ({
        title: `${name} can't even RIGHT NOW`,
        body: `${streak} days. GONE. POOF. ${name} is lying upside down on the couch in existential crisis mode. PLEASE. ONE. PAGE.`,
      }),
    ],
    streak_lost: [
      (name) => ({
        title: `${name} needs a moment...`,
        body: `*dramatic fainting* The streak... is gone... ${name} is inconsolable. But wait - a new streak could heal this wounded heart!`,
      }),
      (name) => ({
        title: `THE TRAGEDY! cries ${name}`,
        body: `${name} is performing a one-Husky mourning opera. But every great drama needs a comeback story. Yours starts now!`,
      }),
      (name) => ({
        title: `${name} has recovered (barely)`,
        body: `After 47 dramatic sighs, ${name} is ready to move on. New streak, new drama, new opportunities for over-the-top celebration!`,
      }),
    ],
    welcome_back: [
      (name) => ({
        title: `${name} is LITERALLY SCREAMING!`,
        body: `AWOOOOOO! YOU'RE BACK! ${name} is doing the most dramatic happy dance the world has ever seen! TEARS OF JOY!`,
      }),
      (name) => ({
        title: `${name} can't handle the emotions!`,
        body: `You're HERE! ${name} has fainted from happiness, recovered, fainted again, and is now doing zoomies. WELCOME BACK!`,
      }),
      (name) => ({
        title: `BREAKING NEWS from ${name}!`,
        body: `EXTRA EXTRA! Beloved human RETURNS! ${name} declares today a national holiday! Reading celebrations to commence IMMEDIATELY!`,
      }),
    ],
    milestone: [
      (name) => ({
        title: `${name} is LOSING IT!`,
        body: `AWOOOOO! THE MILESTONE! ${name} is howling, crying happy tears, and running in circles! THIS IS THE GREATEST DAY IN HISTORY!`,
      }),
      (name) => ({
        title: `${name} can't stop crying!`,
        body: `Happy tears EVERYWHERE! ${name} is SO proud that the dramatic sobbing might never stop! INCREDIBLE MILESTONE!`,
      }),
      (name) => ({
        title: `${name} needs to lie down!`,
        body: `Too. Much. Excitement. ${name} is overwhelmed by your AMAZING achievement. This Husky has never been prouder!`,
      }),
    ],
  },

  german_shepherd: {
    daily_reminder: [
      (name) => ({
        title: `${name}: Reading time. Now.`,
        body: `0800 hours. Book is on the desk. No excuses. ${name} expects full compliance. Move it, reader.`,
      }),
      (name) => ({
        title: `${name} is reporting for duty`,
        body: `Your German Shepherd has your reading schedule memorized. It's time. Fall in and open that book, soldier.`,
      }),
      (name) => ({
        title: `Orders from ${name}`,
        body: `Daily reading quota is non-negotiable. ${name} has your book ready and your excuses filed under "rejected."`,
      }),
      (name) => ({
        title: `${name} checked the clock`,
        body: `You're 0 minutes late to reading time. ${name} intends to keep it that way. Book. Open. Now.`,
      }),
    ],
    streak_risk: [
      (name, streak) => ({
        title: `${name}: This is unacceptable.`,
        body: `${streak}-day streak at risk. ${name} did not train you for ${streak} days to watch you fail now. Read. Immediately.`,
      }),
      (name, streak) => ({
        title: `${name} is disappointed.`,
        body: `A disciplined reader does not skip days. ${streak} days of excellence, and you're considering quitting? ${name} thinks not.`,
      }),
      (name, streak) => ({
        title: `Final warning from ${name}`,
        body: `${streak}-day operational streak in jeopardy. ${name} has zero tolerance for missed days. Execute reading protocol NOW.`,
      }),
    ],
    streak_lost: [
      (name) => ({
        title: `${name}: Debrief required.`,
        body: `Streak lost. ${name} is filing an incident report. Lesson learned. New protocol begins immediately. No repeat failures.`,
      }),
      (name) => ({
        title: `${name} says: Regroup.`,
        body: `Mission failed. But ${name} doesn't dwell on failure - ${name} learns from it. New streak commences at 0600 tomorrow.`,
      }),
      (name) => ({
        title: `${name} has a new plan`,
        body: `The old streak fell. ${name} has already drafted Streak Protocol 2.0. Tighter schedule. Zero tolerance. Let's go.`,
      }),
    ],
    welcome_back: [
      (name) => ({
        title: `${name}: Welcome back to active duty.`,
        body: `Absence noted and logged. ${name} has maintained your reading station in perfect order. Report for duty immediately.`,
      }),
      (name) => ({
        title: `${name} never left their post`,
        body: `Your German Shepherd has been guarding your bookshelf 24/7. Now that you're back, let's resume operations.`,
      }),
      (name) => ({
        title: `${name}: At ease, reader.`,
        body: `Good to have you back in formation. ${name} has your training schedule updated. No time to waste.`,
      }),
    ],
    milestone: [
      (name) => ({
        title: `${name}: Mission accomplished.`,
        body: `Objective achieved with precision. ${name} salutes your dedication. One milestone down. Next target acquired.`,
      }),
      (name) => ({
        title: `${name} approves.`,
        body: `Exceptional performance noted in your file. ${name} is proud. That's the highest compliment a German Shepherd gives.`,
      }),
      (name) => ({
        title: `Commendation from ${name}`,
        body: `${name} has awarded you the Distinguished Reader medal. Outstanding discipline and commitment. Carry on.`,
      }),
    ],
  },

  rottweiler: {
    daily_reminder: [
      (name) => ({
        title: `${name} says: No shortcuts.`,
        body: `Real readers show up every day. ${name} is ready for the long haul. Grab your book - we've got pages to conquer.`,
      }),
      (name) => ({
        title: `${name} is warmed up and ready`,
        body: `Marathon readers don't skip training days. ${name} is at the starting line. Lace up those reading boots.`,
      }),
      (name) => ({
        title: `Tough love from ${name}`,
        body: `Nobody said reading every day was easy. ${name} said it was WORTH IT. Now stop stalling and open that book.`,
      }),
      (name) => ({
        title: `${name} believes in the grind`,
        body: `One page at a time. One day at a time. That's how champions are made. ${name} knows. ${name} has seen it.`,
      }),
    ],
    streak_risk: [
      (name, streak) => ({
        title: `${name}: Don't you dare quit.`,
        body: `${streak} days of grinding, and you're going to throw it away? ${name} didn't raise a quitter. Get back in there.`,
      }),
      (name, streak) => ({
        title: `${name} won't let you fall`,
        body: `${streak} days of endurance is no joke. ${name} has carried you this far. Now carry yourself for one more page.`,
      }),
      (name, streak) => ({
        title: `${name}: Dig deep.`,
        body: `When the streak gets tough, the tough keep reading. ${streak} days proves you have what it takes. Don't stop now.`,
      }),
    ],
    streak_lost: [
      (name) => ({
        title: `${name}: Get back up.`,
        body: `You got knocked down. It happens. ${name} is standing right beside you. Dust off and start the next round.`,
      }),
      (name) => ({
        title: `${name} isn't giving up on you`,
        body: `A lost streak doesn't define you. Your comeback will. ${name} is ready when you are. No rush, but no quitting either.`,
      }),
      (name) => ({
        title: `${name}: Round two.`,
        body: `The first streak was training. The REAL streak starts now. ${name} has seen tougher comebacks. You've got this.`,
      }),
    ],
    welcome_back: [
      (name) => ({
        title: `${name} respects the comeback`,
        body: `You took a break. Now you're back. That takes guts. ${name} is ready to go the distance with you again.`,
      }),
      (name) => ({
        title: `${name}: Let's finish what we started`,
        body: `Welcome back, fighter. ${name} has been keeping the books warm. Time to get back to the grind.`,
      }),
      (name) => ({
        title: `${name} nods in approval`,
        body: `The hardest part is showing back up. You just did it. ${name} is proud. Now let's build something unbreakable.`,
      }),
    ],
    milestone: [
      (name) => ({
        title: `${name}: That's GRIT.`,
        body: `Pure endurance. Pure dedication. ${name} has watched you grind to this milestone and it was worth every page.`,
      }),
      (name) => ({
        title: `${name} tips the crown`,
        body: `Milestone achieved through sheer willpower. ${name} knows that wasn't easy. That's what makes it legendary.`,
      }),
      (name) => ({
        title: `${name}: Unstoppable.`,
        body: `They said you couldn't do it. ${name} always knew you could. This milestone is proof of your endurance.`,
      }),
    ],
  },

  border_collie: {
    daily_reminder: [
      (name) => ({
        title: `${name} checked your progress`,
        body: `Goal: not yet complete. ${name} has calculated the exact pages needed. Let's close that gap NOW.`,
      }),
      (name) => ({
        title: `${name} updated the spreadsheet`,
        body: `Daily target is locked in. ${name} will not rest until every page goal is smashed. Reading time, let's crush it!`,
      }),
      (name) => ({
        title: `${name} is laser-focused`,
        body: `Your Border Collie has one mission: help you hit today's reading target. Distractions? ${name} already herded them away.`,
      }),
      (name) => ({
        title: `Target acquired, says ${name}`,
        body: `${name} has your reading goal in sight and will not stop staring at it until it's done. You know how Border Collies are.`,
      }),
    ],
    streak_risk: [
      (name, streak) => ({
        title: `${name}: TARGET AT RISK!`,
        body: `${streak}-day goal streak in DANGER! ${name} is herding you toward your book RIGHT NOW. Do not resist the Border Collie.`,
      }),
      (name, streak) => ({
        title: `${name} will NOT let this slide`,
        body: `${streak} days of hitting goals and TODAY you might miss?! ${name} is blocking every exit until you read one page.`,
      }),
      (name, streak) => ({
        title: `${name} is giving THE STARE`,
        body: `You know the Border Collie stare. ${name} is doing it right now. ${streak}-day streak. One page. MOVE.`,
      }),
    ],
    streak_lost: [
      (name) => ({
        title: `${name}: Recalculating route`,
        body: `Goal missed. ${name} has already plotted the optimal path to a new streak. No time for regret - only forward progress.`,
      }),
      (name) => ({
        title: `${name} set a new target`,
        body: `Old streak: archived. New goal: loaded. ${name} is obsessed with the NEXT milestone, not the last one.`,
      }),
      (name) => ({
        title: `${name}: New plan, same intensity`,
        body: `${name} spent 0.3 seconds mourning and 5 hours planning the comeback streak. Here's step 1: open your book.`,
      }),
    ],
    welcome_back: [
      (name) => ({
        title: `${name} already has a plan!`,
        body: `Welcome back! ${name} didn't waste a second - your new reading schedule is ready, optimized, and waiting. Let's GO!`,
      }),
      (name) => ({
        title: `${name} herded you back!`,
        body: `Mission: get you reading again. Status: SUCCESS. ${name} has your goals lined up. Time to crush them one by one!`,
      }),
      (name) => ({
        title: `${name}: Finally!`,
        body: `${name} has been staring at the door for days. You're back. Goals are set. No more delays. LET'S ACHIEVE THINGS.`,
      }),
    ],
    milestone: [
      (name) => ({
        title: `${name}: GOAL COMPLETED!`,
        body: `TARGET HIT! ${name} is vibrating with satisfaction! Already calculating the next milestone. But first: CELEBRATE!`,
      }),
      (name) => ({
        title: `${name} crossed it off the list!`,
        body: `Nothing satisfies a Border Collie like a completed goal. ${name} is already eyeing the next one. INCREDIBLE work!`,
      }),
      (name) => ({
        title: `${name}: Precision achieved!`,
        body: `Milestone hit with laser accuracy! ${name} herded every page into place. You and your Border Collie are UNSTOPPABLE.`,
      }),
    ],
  },

  kangal: {
    daily_reminder: [
      (name) => ({
        title: `${name} guards your honor`,
        body: `A warrior reads. A warrior grows. ${name} stands watch while you dive into today's pages. Your honor demands it.`,
      }),
      (name) => ({
        title: `${name} summons you to battle`,
        body: `The reading arena awaits. ${name} has scouted the competition - they're reading. Will you let them surpass you?`,
      }),
      (name) => ({
        title: `${name}: Honor the commitment`,
        body: `You made a promise to read daily. ${name} takes promises seriously. Very seriously. Time to uphold your oath.`,
      }),
      (name) => ({
        title: `${name} stands ready`,
        body: `Your Kangal is a guardian of knowledge. ${name} protects your reading time fiercely. Nobody interrupts. Let's begin.`,
      }),
    ],
    streak_risk: [
      (name, streak) => ({
        title: `${name}: Your honor is at stake!`,
        body: `${streak} days of warrior-level reading about to crumble! ${name} will NOT let dishonor fall upon this house. READ NOW.`,
      }),
      (name, streak) => ({
        title: `${name} howls a battle cry!`,
        body: `WARRIORS DON'T QUIT! ${streak} days of glory must be defended! ${name} stands at the gate - will you stand with your Kangal?`,
      }),
      (name, streak) => ({
        title: `${name}: Protect the streak!`,
        body: `${streak} days is a fortress worth defending. ${name} has never lost a battle and doesn't plan to start now. One page, warrior.`,
      }),
    ],
    streak_lost: [
      (name) => ({
        title: `${name}: A warrior falls, then rises`,
        body: `The streak has fallen in battle. ${name} mourns briefly, then sharpens the sword. A new campaign begins at dawn.`,
      }),
      (name) => ({
        title: `${name}: Honor will be restored`,
        body: `Every great warrior has scars. This lost streak is yours. ${name} will fight beside you for the next one. Rise.`,
      }),
      (name) => ({
        title: `${name} rallies the troops`,
        body: `Defeat is temporary. ${name}'s loyalty is forever. Your Kangal is ready for the next battle. Are you?`,
      }),
    ],
    welcome_back: [
      (name) => ({
        title: `${name}: The warrior returns!`,
        body: `${name} has been guarding your throne in your absence. Welcome back, reader. Your kingdom of books awaits.`,
      }),
      (name) => ({
        title: `${name} stands and salutes!`,
        body: `The guardian has waited faithfully. Now that you're back, ${name} is ready to charge into battle once more!`,
      }),
      (name) => ({
        title: `${name}: Honor is restored`,
        body: `Your return brings honor to the pack. ${name} howls with pride. The league competition trembles at your comeback.`,
      }),
    ],
    milestone: [
      (name) => ({
        title: `${name}: VICTORY!`,
        body: `The battlefield is won! ${name} howls in triumph! This milestone will be remembered in the halls of warriors forever!`,
      }),
      (name) => ({
        title: `${name} crowns you champion!`,
        body: `A milestone worthy of legend! ${name} stands guard over your achievement with fierce pride. HONOR TO THE READER!`,
      }),
      (name) => ({
        title: `${name}: Legendary!`,
        body: `${name} has guarded many readers, but none as mighty as you. This milestone is etched in stone. GLORIOUS!`,
      }),
    ],
  },

  saint_bernard: {
    daily_reminder: [
      (name) => ({
        title: `${name} saved you a cozy spot`,
        body: `No rush. No pressure. ${name} found the comfiest blanket and the perfect reading nook. Join whenever you're ready.`,
      }),
      (name) => ({
        title: `${name} is napping with your book`,
        body: `Your Saint Bernard has been keeping your book warm. Whenever you feel like it, come curl up and read a few pages.`,
      }),
      (name) => ({
        title: `Gentle reminder from ${name}`,
        body: `${name} just wanted to say: there's a book waiting, a warm spot ready, and zero judgment. Read because it feels good.`,
      }),
      (name) => ({
        title: `${name} made hot cocoa (sort of)`,
        body: `Okay, ${name} can't actually make cocoa, but the vibe is right. Cozy reading weather. No pressure, just good pages.`,
      }),
    ],
    streak_risk: [
      (name, streak) => ({
        title: `${name}: Hey, no worries but...`,
        body: `Your ${streak}-day streak might end today. ${name} won't judge either way, but maybe one peaceful page before bed?`,
      }),
      (name, streak) => ({
        title: `${name} gently nudges you`,
        body: `${streak} days is wonderful. ${name} just wants you to know the book is right here if you want it. No pressure, friend.`,
      }),
      (name, streak) => ({
        title: `A calm word from ${name}`,
        body: `Streaks are nice, but ${name} cares more about YOU. That said... ${streak} days would be a shame to lose. Just one page?`,
      }),
    ],
    streak_lost: [
      (name) => ({
        title: `${name}: It's okay, truly`,
        body: `The streak ended, and that's perfectly fine. ${name} is here with a warm blanket. Tomorrow is a beautiful new start.`,
      }),
      (name) => ({
        title: `${name} gives you a big hug`,
        body: `Lost a streak? ${name} doesn't care about numbers. ${name} cares about YOU. Come read when your heart is ready.`,
      }),
      (name) => ({
        title: `${name}: Take your time`,
        body: `The journey matters more than the streak counter. ${name} is patient. Your Saint Bernard will be here whenever you return.`,
      }),
    ],
    welcome_back: [
      (name) => ({
        title: `${name} warms up your spot`,
        body: `Look who's here! ${name} has been keeping everything cozy for you. No rush. Just settle in and enjoy a good book.`,
      }),
      (name) => ({
        title: `${name} gives the gentlest woof`,
        body: `Welcome back, friend. ${name} missed you but never worried. Good readers always come home. The bookshelf is ready.`,
      }),
      (name) => ({
        title: `${name}: Welcome home`,
        body: `${name} has been napping by your reading chair, waiting patiently. You're back. Everything is perfect. Let's read.`,
      }),
    ],
    milestone: [
      (name) => ({
        title: `${name} is quietly proud`,
        body: `A wonderful milestone, achieved at your own pace. ${name} always knew you'd get here. Enjoy this moment.`,
      }),
      (name) => ({
        title: `${name} celebrates with a nap`,
        body: `What better way to honor this milestone than a cozy celebratory nap with a good book? ${name} has the blankets ready.`,
      }),
      (name) => ({
        title: `${name}: Beautifully done`,
        body: `No fanfare needed. ${name} just gives you a warm look that says everything. You did something wonderful. Savor it.`,
      }),
    ],
  },
};

/**
 * Returns a companion-specific notification message based on breed personality.
 * Randomly selects from available templates for variety.
 */
/**
 * Generic daily_goal and weekly_summary templates.
 * Used when a breed doesn't have context-specific messages.
 */
const genericTemplates: Record<string, ((name: string, streakDays?: number) => { title: string; body: string })[]> = {
  daily_goal: [
    (name, _s) => ({
      title: `${name} is watching your progress`,
      body: `You haven't hit your daily reading goal yet! A few more pages and ${name} will be so proud.`,
    }),
    (name) => ({
      title: `Almost there!`,
      body: `${name} believes you can reach today's goal. Even 5 minutes counts!`,
    }),
    (name) => ({
      title: `${name} nudges your book`,
      body: `Your daily page goal is waiting. Pick up where you left off — ${name} will keep you company.`,
    }),
  ],
  weekly_summary: [
    (name) => ({
      title: `${name}'s Weekly Report`,
      body: `Your weekly reading summary is ready! Tap to see how you and ${name} did this week.`,
    }),
    (name) => ({
      title: `Week in review with ${name}`,
      body: `Another week of reading adventures! Check out your stats and celebrate with ${name}.`,
    }),
  ],
};

/**
 * Returns a companion-specific notification message based on breed personality.
 * Randomly selects from available templates for variety.
 */
export function getCompanionMessage(
  breed: string,
  companionName: string,
  context: MessageContext,
  streakDays?: number
): { title: string; body: string } {
  const breedMessages = breedTemplates[breed];

  // Fallback to golden_retriever if breed not found
  let templates = breedMessages
    ? breedMessages[context]
    : breedTemplates["golden_retriever"]?.[context];

  // Fallback to generic templates for contexts not defined per-breed
  if (!templates || templates.length === 0) {
    templates = genericTemplates[context] ?? null;
  }

  if (!templates || templates.length === 0) {
    return {
      title: `${companionName} says hi!`,
      body: `${companionName} is thinking about you. Time to read!`,
    };
  }

  const randomIndex = Math.floor(Math.random() * templates.length);
  return templates[randomIndex](companionName, streakDays);
}
