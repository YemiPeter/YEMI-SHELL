# Framework for Independent Verification of Claims

## 1. Source Triangulation

**Never rely on a single source.** Verify independently using:

- **Primary sources**: Original documents, direct data, first-hand observation
- **Secondary sources**: Analysis and interpretation of primary sources
- **Tertiary sources**: Summaries and overviews (use only for orientation, never as evidence)

**Cross-reference technique**:
- Find ≥2 independent sources that confirm the same claim
- If sources conflict, trace each back to its primary source
- Check if sources are citing the same original data or making independent measurements

## 2. Source Credibility Assessment

Evaluate every source against these criteria:

| Criterion | Questions to Ask |
|-----------|------------------|
| **Authority** | Who authored it? What are their qualifications? Do they have relevant expertise? |
| **Accuracy** | Can facts be verified elsewhere? Is there evidence of error correction? |
| **Currency** | When was it published? Is the information still current? |
| **Coverage** | Does it address the full scope of the claim? What's omitted? |
| **Objectivity** | Who funds or sponsors this source? What do they gain from this claim? |
| **Methodology** | How was the data collected? Is the method replicable? Sample size adequate? |

**Red flags**: Anonymous authorship, no citations, emotional language, pressure to act immediately, claims that seem too good/bad to be true.

## 3. Bias Detection Framework

**Systematic bias checks**:

1. **Funding trail**: Follow the money. Research who pays for the source and whether they benefit from specific outcomes
2. **Selection bias**: Was the sample/population selected to produce a predetermined result?
3. **Confirmation bias**: Is the source only presenting evidence that supports one side?
4. **Publication bias**: Are negative/null results being suppressed?
5. **Anchoring**: Is the argument relying too heavily on the first piece of evidence presented?

**Technique**: Actively seek out the strongest counterargument to any claim. If you cannot find a credible opposing view, your search may be biased.

## 4. Logical Fallacy Identification

Common patterns to watch for:

| Fallacy | Pattern | Detection Question |
|---------|---------|-------------------|
| **Appeal to authority** | "Expert X says Y" | Is X actually an expert in THIS specific domain? |
| **Anecdotal evidence** | "This happened to me, so..." | Isolated case vs. systematic data? |
| **Correlation ≠ causation** | A and B correlate | Is there a plausible mechanism? Could C cause both? |
| **Confirmation bias** | Only citing supporting evidence | What evidence would falsify this claim? |
| **False dichotomy** | "Either A or B" | Are there actually more options? |
| **Moving the goalposts** | Evidence dismissed as "not enough" | What specific evidence would satisfy the claim? |
| **Appeal to tradition** | "We've always done it this way" | Does tradition equal correctness? |
| **Ad hominem** | Attacking the person | Does the attack address the actual argument? |

## 5. Practical Verification Techniques

### For factual claims:
1. **Go to the original source**: If a study is cited, find and read the study, not the summary
2. **Check replication**: Has this finding been replicated by independent researchers?
3. **Look for retractions/corrections**: Search "retraction" + claim keywords

### For data/statistics:
1. **Examine the raw data**: If possible, access the dataset itself
2. **Check the math**: Replicate calculations independently
3. **Question the metric**: Does the measurement actually measure what it claims to measure?

### For process/implementation claims (e.g., code, systems):
1. **Direct observation**: Inspect the actual system/file/state yourself rather than trusting documentation
2. **Reproduce the result**: Execute the described process and see if you get the claimed outcome
3. **Compare stated vs. actual state**: Document what the documentation claims, then verify the real state

## 6. Self-Validation Protocol

**Before accepting any claim as true**:

1. **State the claim precisely**: Express it in neutral, specific language without emotionally loaded terms
2. **Identify what would falsify it**: Define exact conditions that would prove the claim false
3. **Seek disconfirming evidence**: Actively look for evidence against the claim, not just for it
4. **Check your own bias**: Ask "What do I want to be true here?" and "What would I lose if this is wrong?"
5. **Time-delay test**: If still uncertain, wait. Time often reveals truth as more evidence emerges
6. **Peer review**: Explain the claim and your verification to someone unfamiliar with it — gaps in explanation reveal weak spots

## 7. Structured Doubt Register

Maintain a running record of unverified claims:

```
Claim: [specific statement]
Source: [who said it]
Evidence presented: [what was shown]
Evidence I independently verified: [what you checked]
Remaining uncertainties: [what's still unconfirmed]
Confidence level: [high/medium/low]
Reasoning: [why]
```

Update this register as you gather more information. This forces explicit reasoning and prevents hindsight bias.

## 8. The Provenance Chain

For any piece of information, trace it backward:

```
Claim → Source → Source's source → Primary data/original observation
```

Breakdowns typically occur at transitions between levels. The weaker the link between "source said X" and "source observed X firsthand," the less confidence you should have.

## Key Principle

**Extraordinary claims require extraordinary evidence.** The burden of proof lies with the claimant, not the skeptic. Your default position should be skeptical withholding of judgment, not immediate acceptance — but also not immediate rejection. Maintain provisional conclusions that update as new evidence arrives.
