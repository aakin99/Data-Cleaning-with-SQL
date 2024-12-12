/*

Cleaning Data in SQL Queries

*/

--------------------------------------------------------------------------------------------------------------------

-- Standardize Data Format

USE master;  
GO  
ALTER DATABASE "Data Cleaning in SQL" SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
ALTER DATABASE "Data Cleaning in SQL" MODIFY NAME = Data_Cleaning_SQL;
GO  
ALTER DATABASE Data_Cleaning_SQL SET MULTI_USER;
GO

ALTER TABLE Data_Cleaning_SQL.dbo.NashvilleHousing
ADD SaleDate2 DATE;

Update Data_Cleaning_SQL.dbo.NashvilleHousing
SET Saledate2 = CONVERT(Date, Saledate);

Select Saledate2, CONVERT(Date, Saledate)
From Data_Cleaning_SQL.dbo.NashvilleHousing;


-- Populate Property Address Data

Select *
From Data_Cleaning_SQL.dbo.NashvilleHousing
-- WHERE PropertyAddress is null
ORDER BY ParcelID


-- Finding property addresses with a null value, joining to find subsiquent property address, using isnull to populate null column (35 rows affected)
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From Data_Cleaning_SQL.dbo.NashvilleHousing a
JOIN Data_Cleaning_SQL.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID] 
 WHERE a.PropertyAddress is null

 -- Updating table to reflect populated property address
UPDATE a
SET PropertyAddress= ISNULL(a.PropertyAddress, b.PropertyAddress)
From Data_Cleaning_SQL.dbo.NashvilleHousing a
JOIN Data_Cleaning_SQL.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID] 
WHERE a.PropertyAddress is null

-- Breaking out address into Individual Columns (Address, City, State)

Select PropertyAddress
From Data_Cleaning_SQL.dbo.NashvilleHousing
-- WHERE PropertyAddress is null
-- ORDER BY ParcelID

-- Using CharIndex to seperate Address Column to first ","

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address2

From Data_Cleaning_SQL.dbo.NashvilleHousing;

-- Creating new Columns for Property Address & City

ALTER TABLE Data_Cleaning_SQL.dbo.NashvilleHousing
ADD PropertySplitAddress NvarChar(255);

ALTER TABLE Data_Cleaning_SQL.dbo.NashvilleHousing
ADD PropertySplitCity NvarChar(255);

Update Data_Cleaning_SQL.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1);

Update Data_Cleaning_SQL.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress));

-- Using Parsename to seperate Owner Address Column into Address, City and State

SELECT 
PARSENAME(Replace(OwnerAddress, ',', '.'), 1) as OwnerSplitState,
PARSENAME(Replace(OwnerAddress, ',', '.'), 2) as OwnerSplitCity,
PARSENAME(Replace(OwnerAddress, ',', '.'), 3) as OwnerSplitAddress

From Data_Cleaning_SQL.dbo.NashvilleHousing;

-- Creating new Columns for Owner Address, City & State

ALTER TABLE Data_Cleaning_SQL.dbo.NashvilleHousing
ADD OwnerSplitState NvarChar(255);

ALTER TABLE Data_Cleaning_SQL.dbo.NashvilleHousing
ADD OwnerSplitCity NvarChar(255);

ALTER TABLE Data_Cleaning_SQL.dbo.NashvilleHousing
ADD OwnerSplitAddress NvarChar(255);

Update Data_Cleaning_SQL.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(Replace(OwnerAddress, ',', '.'), 3)

Update Data_Cleaning_SQL.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(Replace(OwnerAddress, ',', '.'), 2)

Update Data_Cleaning_SQL.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(Replace(OwnerAddress, ',', '.'), 1)

Select Saledate2, CONVERT(Date, Saledate)
From Data_Cleaning_SQL.dbo.NashvilleHousing;

-- Make values in SoldAsVacant Column Cohesive 

SELECT Distinct (SoldAsVacant), COUNT(SoldAsVacant)
From Data_Cleaning_SQL.dbo.NashvilleHousing
Group By SoldAsVacant
Order By 2

SELECT SoldAsVacant,
CASE When SoldAsVacant = 'Y' THEN 'Yes'
	When SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
From Data_Cleaning_SQL.dbo.NashvilleHousing;

Update Data_Cleaning_SQL.dbo.NashvilleHousing
SET SoldAsVacant = 
	CASE When SoldAsVacant = 'Y' THEN 'Yes'
	When SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END;

-- Creating New Table to Remove Duplicates

SELECT *
	INTO Data_Cleaning_SQL.dbo.NashvilleHousingRemovedDup
From Data_Cleaning_SQL.dbo.NashvilleHousing ;

-- Removing Duplicates with CTE by Partitioning with Row_Number
WITH RowNumT AS (
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice, 
				SaleDate,
				LegalReference 
				ORDER BY UniqueID) 
				row_num
FROM Data_Cleaning_SQL.dbo.NashvilleHousingRemovedDup
)
DELETE 
-- SELECT *
From RowNumT
Where row_num > 1
-- ORDER BY PropertyAddress
 
 -- Removing Unused Cloumns to Prepare Data for Analysis

 Select *
From Data_Cleaning_SQL.dbo.NashvilleHousingRemovedDup

ALTER TABLE Data_Cleaning_SQL.dbo.NashvilleHousingRemovedDup
DROP COLUMN PropertyAddress, TaxDistrict, OwnerAddress, SaleDate, SaleDate2

ALTER TABLE Data_Cleaning_SQL.dbo.NashvilleHousingRemovedDup
DROP COLUMN SaleDate2
