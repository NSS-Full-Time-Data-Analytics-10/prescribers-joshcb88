SELECT *
FROM prescription
--Q1
--a. prescriber with higehst total number of claims
SELECT DISTINCT (prescriber.npi) AS NPI,SUM(prescription.total_claim_count) AS highest_claim_count
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY NPI
ORDER BY highest_claim_count DESC;
--b.
SELECT DISTINCT prescriber.npi AS NPI,SUM(prescription.total_claim_count) AS highest_claim_count,
	   nppes_provider_first_name AS first_name,nppes_provider_last_org_name AS last_name,
	   specialty_description AS spc_descript
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY NPI,first_name,last_name,spc_descript
ORDER BY highest_claim_count DESC;
--Q2.
--a. specialty highest claim
SELECT DISTINCT specialty_description AS spc_descript,SUM(prescription.total_claim_count) AS highest_claim_count
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY spc_descript
ORDER BY highest_claim_count DESC;
--b. specialty total opioids
SELECT DISTINCT specialty_description AS spc_descript, SUM(total_claim_count) AS total_claim_count,drug.opioid_drug_flag
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
WHERE drug.opioid_drug_flag='Y'
GROUP BY spc_descript,drug.opioid_drug_flag
ORDER BY total_claim_count DESC;
--c.
SELECT DISTINCT specialty_description
FROM prescriber 
WHERE NOT EXISTS 
    (SELECT * 
     FROM prescription
     WHERE prescriber.npi =prescription.npi)
--3.
--a. Generic drug name had highest cost
SELECT DISTINCT generic_name,SUM(total_drug_cost) AS total_cost
FROM prescription
INNER JOIN drug
USING(drug_name)
GROUP BY generic_name
ORDER BY total_cost DESC;
--b. Generic drug name highest cost per day
SELECT ROUND(SUM(total_drug_cost)/SUM(total_day_supply),2) AS cost_per_day,generic_name AS generic_drug_name
FROM prescription
INNER JOIN drug
USING(drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC;
--Q4.
--a. Opioid, Antibiotic or Neither
SELECT DISTINCT drug_name,
CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
	 WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
	 WHEN opioid_drug_flag<>'Y' AND antibiotic_drug_flag<>'Y' THEN 'neither' END As drug_type
FROM drug

--b.
SELECT SUM(total_drug_cost)::money AS total_cost,
CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
	 WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
	 WHEN opioid_drug_flag<>'Y' AND antibiotic_drug_flag<>'Y' THEN 'neither' END As drug_type
FROM drug
INNER JOIN prescription
USING (drug_name)
GROUP BY drug_type
ORDER BY total_cost DESC;
--Q5 
--a.CBSAs in TN
SELECT COUNT (DISTINCT cbsa)
FROM cbsa AS c
INNER JOIN fips_county AS f
USING(fipscounty)
WHERE f.state = 'TN'
--b.Largest combined population
SELECT SUM(p.population), c.cbsaname
FROM cbsa AS c
INNER JOIN population AS p
USING( fipscounty)
GROUP BY  c.cbsaname 
ORDER BY SUM(p.population) DESC;
--c. Largest county not in CBSA report
SELECT f.county, p.population
FROM fips_county AS f
LEFT JOIN population AS p 
USING (fipscounty)
LEFT JOIN cbsa AS c
USING (fipscounty)
WHERE state='TN' and cbsa IS NULL
ORDER BY p.population DESC NULLS LAST;
--Q6
--a.
SELECT drug_name,total_claim_count
FROM prescription
WHERE total_claim_count>=3000
ORDER BY total_claim_count DESC;
--b.
SELECT drug_name,total_claim_count,
CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
     ELSE 'Not_opioid' END AS category
FROM prescription
INNER JOIN drug
USING (drug_name)
WHERE total_claim_count>=3000
ORDER BY total_claim_count DESC;
--c. 
SELECT nppes_provider_first_name AS first_name,prescriber.nppes_provider_last_org_name AS last_name,drug_name,total_claim_count,
CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
     ELSE 'Not_opioid' END AS category
FROM prescription
INNER JOIN prescriber
USING (npi)
INNER JOIN drug
USING (drug_name)
WHERE total_claim_count>=3000
ORDER BY total_claim_count DESC;
--Q7,
--a. List of npi and drug number combinations
SELECT npi,drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description='Pain Management'
AND nppes_provider_city='NASHVILLE'
AND opioid_drug_flag='Y'
GROUP BY npi,drug_name
ORDER BY npi;
--b.
SELECT npi,drug.drug_name,SUM(total_claim_count) AS claims
FROM prescriber CROSS JOIN drug
FULL JOIN prescription USING (npi,drug_name)
WHERE specialty_description='Pain Management'
	AND nppes_provider_city='NASHVILLE'
	AND opioid_drug_flag='Y'
GROUP BY npi,drug.drug_name
ORDER BY claims DESC NULLS LAST;
--c.
SELECT npi,drug.drug_name,COALESCE(SUM(total_claim_count),0) AS claims
FROM prescriber CROSS JOIN drug
FULL JOIN prescription USING (npi,drug_name)
WHERE specialty_description='Pain Management'
	AND nppes_provider_city='NASHVILLE'
	AND opioid_drug_flag='Y'
GROUP BY npi,drug.drug_name
ORDER BY claims DESC;

SELECT population, county
FROM population
FULL JOIN cbsa USING(fipscounty)
FULL JOIN fips_county USING(fipscounty)
WHERE cbsa IS NULL
ORDER BY population DESC NULLS LAST;