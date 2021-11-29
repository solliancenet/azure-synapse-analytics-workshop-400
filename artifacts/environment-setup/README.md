# Event preflight checklist

When preparing for an L-400 event delivery, perform the following before the start of the event:

1. Reset the mentimeter answers.
2. Update slides with menti codes.
3. Prepare whiteboard links for each of the table groups.
4. Sign in into the Whiteboard app (to demo the correct use to the audience at the end of the first presentation).
5. Request six (one per proctor) L400 environments from cloudlabs-support@spektrasystems.com.
6. Confirm that the environments include the required data for the labs and exercises.
7. Setup scheduling application (<https://aka.solliance.net/synapse-schedule>)
8. Reset the public repo (<https://github.com/solliancenet/data-ai-technical-bootcamp>):
   1. Checkout

        `git checkout --orphan latest_branch`

   2. Add all the files

        `git add -A`

   3. Commit the changes

        `git commit -am "Fresh start"`

   4. Delete the branch

        `git branch -D master`

   5. Rename the current branch to master

        `git branch -m master`

   6. Finally, force update your repository

        `git push -f origin master`
