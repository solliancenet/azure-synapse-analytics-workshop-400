# Environment setup checklist

When preparing for an L-400 event delivery, perform the following before the start of the event:

1. Reset the mentimeter answers.
2. Update slides with menti codes.
3. Prepare whiteboard links for each of the table groups.
4. Request six (one per proctor) L400 environments from cloudlabs-support@spektrasystems.com.
5. Confirm that the environments include the required data for the labs and exercises.
6. Reset the public repo (<https://github.com/solliancenet/data-ai-technical-bootcamp>):
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
