#!/bin/bash

VERSION=0.5.0
FORMAT=tar.gz
LINK=https://github.com/relic-toolkit/relic
RELIC=${1:-relic-toolkit-${VERSION}}
# commit of as of 1/9/2019
# comment 'Update LABEL with recent changes'
COMMIT=b984e901ba78c83ea4093ea96addd13628c8c2d0

echo "Clone github repo @ ${LINK}"
git clone ${LINK} ${RELIC}.git
cd ${RELIC}.git
git reset --hard ${COMMIT}

if [[ ! -f ../${RELIC}.${FORMAT} ]]; then
   echo "Create archive of source (without git files)"
   git archive --output ../${RELIC}.test.${FORMAT} HEAD 

   echo "Create final tarball: ${RELIC}.${FORMAT}"
   cd ..
   mkdir ${RELIC}
   cd ${RELIC}
   tar -xf ../${RELIC}.test.${FORMAT}

   echo "Fix symbols..."
   grep -rl "MIN" ./ | xargs sed --in-place 's/MIN/RLC_MIN/g'
   grep -rl "MAX" ./ | xargs sed --in-place 's/MAX/RLC_MAX/g'
   grep -rl "ALIGN" ./ | xargs sed --in-place 's/ALIGN/RLC_ALIGN/g'
   grep -rl "rsa_t" ./ | xargs sed --in-place 's/rsa_t/rlc_rsa_t/g'
   grep -rl "rsa_st" ./ | xargs sed --in-place 's/rsa_st/rlc_rsa_st/g'
   sed --in-place -e '/^#define ep2_mul /d' include/relic_label.h

   # RELIC 0.5.0 vendors the BLAKE2 reference header with packed structs whose
   # state types are also explicitly 64-byte aligned. Newer GCC rejects arrays
   # of those aligned types inside packed structs with:
   #   size of array element is not a multiple of its alignment
   # The BLAKE2 code here does not require those state typedefs to be over-
   # aligned for OpenABE, so remove the explicit alignment while preserving
   # the packed parameter structs.
   sed --in-place \
       -e 's/RLC_ALIGNME( 64 ) typedef struct __blake2s_state/typedef struct __blake2s_state/' \
       -e 's/RLC_ALIGNME( 64 ) typedef struct __blake2b_state/typedef struct __blake2b_state/' \
       src/md/blake2.h

   cd ..
   tar -czf ${RELIC}.${FORMAT} ${RELIC}
   rm ${RELIC}.test.${FORMAT}
   rm -r ${RELIC}
else
   echo "[!] ${RELIC}.tar.gz already exists." 
fi
