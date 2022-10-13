
export const getCreators = (array) => {
  const finalized = [];

  const result = array.reduce((res, currentValue) => {
    (res[currentValue.seller] = res[currentValue.seller] || []).push(currentValue);

    return res;
  }, {});

  Object.entries(result).forEach((itm) => {
    const seller = itm[0];
    const sumAll = itm[1].map((item) => Number(item.price)).reduce((prev, curr) => prev + curr, 0);

    finalized.push({ seller, sumAll });
  });
  // sort to show best seller account as 1
  return finalized.sort((a, b) => b.sumAll - a.sumAll);
};
