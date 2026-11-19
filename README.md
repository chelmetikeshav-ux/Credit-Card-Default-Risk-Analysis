# Credit-Card-Default-Risk-Analysis

I used SQL (PostgreSQL) to analyze 30,000 credit card customers and find out who is most likely to default next month.

Dataset

"Default of Credit Card Clients" (UCI / Kaggle): 30,000 customers with credit limit, age, education, 6 months of payment history, and whether they defaulted.

Tools

PostgreSQL, SQL, Python (pandas) for loading the data

Files
load_data.py loads the CSV into PostgreSQL
queries.sql has the 15 analysis queries
How to run
Create a PostgreSQL database called creditdb
pip install pandas sqlalchemy psycopg2-binary
python load_data.py UCI_Credit_Card.csv postgresql://postgres:YOUR_PASSWORD@localhost:5432/creditdb
Run the queries in queries.sql one at a time
Key findings
Overall default rate is 22.1% (6,636 of 30,000 customers).
Late payments are the strongest signal: 11.7% default with no late months vs 70.3% with 6 late months.
Customers late 3 months in a row default at 63.8%, vs 17.9% for others.
Credit limits under 50K default at 36.1%, vs 15.1% for 200K+.
A simple risk score splits customers into High (59.5%), Medium (30.1%) and Low (13.3%) default rates.

Part 1: Who defaults?

Q1: Portfolio overview. It sets the baseline that everything else is compared against. Of 30,000 customers, 6,636 defaulted, which is 22.1%.

Q2: Default rate by age. It tests whether age is linked to risk. The pattern is U-shaped: under 25 defaults at 27.2%, ages 25-34 at 20.3% (the safest), and 55+ at 26.7%.

Q3: Default rate by credit limit. It tests whether customers with higher limits default less. They do, strongly: 36.1% for limits under 50K down to 15.1% for 200K+. This partly reflects the bank’s own earlier judgment, since banks give higher limits to customers they already trust.

Q4: Education and marital status (uses JOIN). It tests whether risk differs between customer profiles. Graduate-school single customers are among the lowest at 18.4%, and high-school married customers are among the highest at 26.4%. HAVING COUNT(*) >= 100 removes tiny groups so a few customers can’t distort the result.

Part 2: Which behaviors signal risk?

Q5: Utilization, defaulters vs non-defaulters. It tests whether defaulters use more of their credit limit. Slightly: 0.49 vs 0.40. Defaulters’ average bill is actually lower (48,509 vs 51,994), so the size of the bill alone doesn’t explain default.

Q6: Default rate by utilization band. It tests whether risk jumps at a certain utilization level. Risk rises from 16.8% (under 25%) to about 26% at 50% and above, then flattens, so there is no sharp jump at 80%.

Q7: Late months out of 6. It tests whether more late months mean higher risk. This is the strongest signal in the project: 11.7% with 0 late months, 29.8% with 1, 50.9% with 3, and 70.3% with 6.

Q8: Late 3 months in a row. It tests whether recent, repeated lateness is especially dangerous. The 2,737 customers late in each of the last 3 months default at 63.8%, vs 17.9% for everyone else.

Q9: How much of the bill customers pay. It tests whether minimum payers are riskier than full payers. Customers who pay under 5% of their bill default at 27.9%, and those who pay in full at 13.9%.

Part 3: Testing assumptions, then acting

Q10: Balance deciles (NTILE). It tests the common assumption that bigger balances are riskier. The assumption fails here: the top 10% by balance default at 19.8%, below the 22.1% average, and no clear pattern runs across the deciles.

Q11: Top 3 balances per education group (RANK, PARTITION BY). This one proves a skill more than a fact. It lists the highest-balance customers within each segment, such as a 964,511 balance on a 1,000,000 limit, a view you could use for account monitoring.

Q12: Six-month bill trend. It tests whether defaulters’ balances grow faster before they default. They don’t: both groups’ bills rise about the same amount, and defaulters’ are slightly lower. This agrees with Q10: payment behavior matters more than balance.

Q13: High-risk segment. It tests whether combining two signals, utilization of 80% or more and late last month, finds a much riskier group. It does: 2,141 customers default at 56.2%, vs 19.5% for the rest, which is 2.54x the average.

Q14: How many defaulters the segment catches. It tests whether that segment is enough on its own. It’s precise but narrow: contacting 7.1% of customers reaches only 18.1% of defaulters, so most defaulters sit outside it.

Q15: Risk score and tiers. It tests whether a simple points-based rule can rank customers into clearly different risk levels. It can: High defaults at 59.5%, Medium at 30.1%, Low at 13.3%, and the order is consistent. One caveat is that I built and tested the rule on the same data, so it hasn’t been tested on new customers.

Recommendation

Contact customers with recent late payments first. The High-risk tier is about 10% of customers but defaults at nearly 60%.

Author: Keshav Chelmeti
