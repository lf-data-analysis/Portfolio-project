SELECT *
FROM [Portfolio Project]..Sheet1$


--Converting fields to types of data which are easier to use.

SELECT SaleDateConverted, CONVERT(Date,SaleDate)
FROM [Portfolio Project]..Sheet1$


Update [Portfolio Project]..Sheet1$
SET SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE [Portfolio Project]..Sheet1$
Add SaleDateConverted Date;

Update [Portfolio Project]..Sheet1$
SET SaleDateConverted = CONVERT(Date,SaleDate)




--Populate Property Address data using join clause. This is because certain parts of data are only available on one of the tables.
--Only doing so when there is null data doesn't waste time on already populated addresses.

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM [Portfolio Project]..Sheet1$ a
JOIN [Portfolio Project]..Sheet1$ b
    ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL



UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM [Portfolio Project]..Sheet1$ a
JOIN [Portfolio Project]..Sheet1$ b
    ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


--Address has multiple parts of data in one column. This makes it hard to sort through.
--The following code breaks the address into newly created individual columns for address, city and state.

SELECT *
FROM [Portfolio Project]..Sheet1$

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 ,LEN(PropertyAddress)) AS Address

FROM [Portfolio Project]..Sheet1$

ALTER TABLE [Portfolio Project]..Sheet1$
Add PropertySplitAddress Nvarchar(255);

Update [Portfolio Project]..Sheet1$
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

ALTER TABLE [Portfolio Project]..Sheet1$
Add PropertySplitCity Nvarchar(255);

Update [Portfolio Project]..Sheet1$
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 ,LEN(PropertyAddress))

SELECT OwnerAddress
FROM [Portfolio Project]..Sheet1$


SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)
FROM [Portfolio Project]..Sheet1$

ALTER TABLE [Portfolio Project]..Sheet1$
Add OwnerSplitAddress Nvarchar(255);

Update [Portfolio Project]..Sheet1$
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,3)

ALTER TABLE [Portfolio Project]..Sheet1$
Add OwnerSplitCity Nvarchar(255);

Update [Portfolio Project]..Sheet1$
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,2)

ALTER TABLE [Portfolio Project]..Sheet1$
Add OwnerSplitState Nvarchar(255);

Update [Portfolio Project]..Sheet1$
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') ,1)




--A Count on how many properties are sold as vacant.
SELECT DISTINCT(SoldAsVacant), Count(SoldAsVacant)
FROM [Portfolio Project]..Sheet1$
GROUP BY soldAsVacant
ORDER BY 2

UPDATE [Portfolio Project]..Sheet1$
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END





--The next code removes duplicate sets of data
WITH RowNumCTE AS(
SELECT *,
    ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
	             PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
				    UniqueID
					) row_num




FROM [Portfolio Project]..Sheet1$
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY propertyaddress




--Getting rid of unused columns


SELECT *
FROM [Portfolio Project]..Sheet1$


ALTER TABLE [Portfolio Project]..Sheet1$
DROP COLUMN SaleDate, OwnerAddress, TaxDistrict, PropertyAddress
